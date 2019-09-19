
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

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
  Call_PostAddTagsToResource_601024 = ref object of OpenApiRestCall_600410
proc url_PostAddTagsToResource_601026(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_601025(path: JsonNode; query: JsonNode;
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
  var valid_601027 = query.getOrDefault("Action")
  valid_601027 = validateParameter(valid_601027, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601027 != nil:
    section.add "Action", valid_601027
  var valid_601028 = query.getOrDefault("Version")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601028 != nil:
    section.add "Version", valid_601028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601029 = header.getOrDefault("X-Amz-Date")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Date", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Security-Token")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Security-Token", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Content-Sha256", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Algorithm")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Algorithm", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Signature", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-SignedHeaders", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Credential")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Credential", valid_601035
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601036 = formData.getOrDefault("Tags")
  valid_601036 = validateParameter(valid_601036, JArray, required = true, default = nil)
  if valid_601036 != nil:
    section.add "Tags", valid_601036
  var valid_601037 = formData.getOrDefault("ResourceName")
  valid_601037 = validateParameter(valid_601037, JString, required = true,
                                 default = nil)
  if valid_601037 != nil:
    section.add "ResourceName", valid_601037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601038: Call_PostAddTagsToResource_601024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_601038.validator(path, query, header, formData, body)
  let scheme = call_601038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601038.url(scheme.get, call_601038.host, call_601038.base,
                         call_601038.route, valid.getOrDefault("path"))
  result = hook(call_601038, url, valid)

proc call*(call_601039: Call_PostAddTagsToResource_601024; Tags: JsonNode;
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
  var query_601040 = newJObject()
  var formData_601041 = newJObject()
  if Tags != nil:
    formData_601041.add "Tags", Tags
  add(query_601040, "Action", newJString(Action))
  add(formData_601041, "ResourceName", newJString(ResourceName))
  add(query_601040, "Version", newJString(Version))
  result = call_601039.call(nil, query_601040, nil, formData_601041, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_601024(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_601025, base: "/",
    url: url_PostAddTagsToResource_601026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_600752 = ref object of OpenApiRestCall_600410
proc url_GetAddTagsToResource_600754(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_600753(path: JsonNode; query: JsonNode;
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
  var valid_600866 = query.getOrDefault("Tags")
  valid_600866 = validateParameter(valid_600866, JArray, required = true, default = nil)
  if valid_600866 != nil:
    section.add "Tags", valid_600866
  var valid_600867 = query.getOrDefault("ResourceName")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = nil)
  if valid_600867 != nil:
    section.add "ResourceName", valid_600867
  var valid_600881 = query.getOrDefault("Action")
  valid_600881 = validateParameter(valid_600881, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_600881 != nil:
    section.add "Action", valid_600881
  var valid_600882 = query.getOrDefault("Version")
  valid_600882 = validateParameter(valid_600882, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600882 != nil:
    section.add "Version", valid_600882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600883 = header.getOrDefault("X-Amz-Date")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Date", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Security-Token")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Security-Token", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Content-Sha256", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Algorithm")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Algorithm", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Signature")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Signature", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-SignedHeaders", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Credential")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Credential", valid_600889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_GetAddTagsToResource_600752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_GetAddTagsToResource_600752; Tags: JsonNode;
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
  var query_600984 = newJObject()
  if Tags != nil:
    query_600984.add "Tags", Tags
  add(query_600984, "ResourceName", newJString(ResourceName))
  add(query_600984, "Action", newJString(Action))
  add(query_600984, "Version", newJString(Version))
  result = call_600983.call(nil, query_600984, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_600752(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_600753, base: "/",
    url: url_GetAddTagsToResource_600754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_601060 = ref object of OpenApiRestCall_600410
proc url_PostApplyPendingMaintenanceAction_601062(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyPendingMaintenanceAction_601061(path: JsonNode;
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
  var valid_601063 = query.getOrDefault("Action")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_601063 != nil:
    section.add "Action", valid_601063
  var valid_601064 = query.getOrDefault("Version")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601064 != nil:
    section.add "Version", valid_601064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601065 = header.getOrDefault("X-Amz-Date")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Date", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Security-Token")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Security-Token", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Content-Sha256", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Algorithm")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Algorithm", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Signature", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-SignedHeaders", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Credential")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Credential", valid_601071
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
  var valid_601072 = formData.getOrDefault("ApplyAction")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "ApplyAction", valid_601072
  var valid_601073 = formData.getOrDefault("ResourceIdentifier")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "ResourceIdentifier", valid_601073
  var valid_601074 = formData.getOrDefault("OptInType")
  valid_601074 = validateParameter(valid_601074, JString, required = true,
                                 default = nil)
  if valid_601074 != nil:
    section.add "OptInType", valid_601074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_PostApplyPendingMaintenanceAction_601060;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_PostApplyPendingMaintenanceAction_601060;
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
  var query_601077 = newJObject()
  var formData_601078 = newJObject()
  add(query_601077, "Action", newJString(Action))
  add(formData_601078, "ApplyAction", newJString(ApplyAction))
  add(formData_601078, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_601078, "OptInType", newJString(OptInType))
  add(query_601077, "Version", newJString(Version))
  result = call_601076.call(nil, query_601077, nil, formData_601078, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_601060(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_601061, base: "/",
    url: url_PostApplyPendingMaintenanceAction_601062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_601042 = ref object of OpenApiRestCall_600410
proc url_GetApplyPendingMaintenanceAction_601044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyPendingMaintenanceAction_601043(path: JsonNode;
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
  var valid_601045 = query.getOrDefault("ApplyAction")
  valid_601045 = validateParameter(valid_601045, JString, required = true,
                                 default = nil)
  if valid_601045 != nil:
    section.add "ApplyAction", valid_601045
  var valid_601046 = query.getOrDefault("ResourceIdentifier")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "ResourceIdentifier", valid_601046
  var valid_601047 = query.getOrDefault("Action")
  valid_601047 = validateParameter(valid_601047, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_601047 != nil:
    section.add "Action", valid_601047
  var valid_601048 = query.getOrDefault("OptInType")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = nil)
  if valid_601048 != nil:
    section.add "OptInType", valid_601048
  var valid_601049 = query.getOrDefault("Version")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601049 != nil:
    section.add "Version", valid_601049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601057: Call_GetApplyPendingMaintenanceAction_601042;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_601057.validator(path, query, header, formData, body)
  let scheme = call_601057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601057.url(scheme.get, call_601057.host, call_601057.base,
                         call_601057.route, valid.getOrDefault("path"))
  result = hook(call_601057, url, valid)

proc call*(call_601058: Call_GetApplyPendingMaintenanceAction_601042;
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
  var query_601059 = newJObject()
  add(query_601059, "ApplyAction", newJString(ApplyAction))
  add(query_601059, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_601059, "Action", newJString(Action))
  add(query_601059, "OptInType", newJString(OptInType))
  add(query_601059, "Version", newJString(Version))
  result = call_601058.call(nil, query_601059, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_601042(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_601043, base: "/",
    url: url_GetApplyPendingMaintenanceAction_601044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_601098 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBClusterParameterGroup_601100(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterParameterGroup_601099(path: JsonNode;
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
  var valid_601101 = query.getOrDefault("Action")
  valid_601101 = validateParameter(valid_601101, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_601101 != nil:
    section.add "Action", valid_601101
  var valid_601102 = query.getOrDefault("Version")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601102 != nil:
    section.add "Version", valid_601102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601103 = header.getOrDefault("X-Amz-Date")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Date", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Security-Token")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Security-Token", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
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
  var valid_601110 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = nil)
  if valid_601110 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_601110
  var valid_601111 = formData.getOrDefault("Tags")
  valid_601111 = validateParameter(valid_601111, JArray, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "Tags", valid_601111
  var valid_601112 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_601112
  var valid_601113 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = nil)
  if valid_601113 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_601113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_PostCopyDBClusterParameterGroup_601098;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_PostCopyDBClusterParameterGroup_601098;
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
  var query_601116 = newJObject()
  var formData_601117 = newJObject()
  add(formData_601117, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_601117.add "Tags", Tags
  add(query_601116, "Action", newJString(Action))
  add(formData_601117, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_601117, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_601116, "Version", newJString(Version))
  result = call_601115.call(nil, query_601116, nil, formData_601117, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_601098(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_601099, base: "/",
    url: url_PostCopyDBClusterParameterGroup_601100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_601079 = ref object of OpenApiRestCall_600410
proc url_GetCopyDBClusterParameterGroup_601081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterParameterGroup_601080(path: JsonNode;
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
  var valid_601082 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_601082
  var valid_601083 = query.getOrDefault("Tags")
  valid_601083 = validateParameter(valid_601083, JArray, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "Tags", valid_601083
  var valid_601084 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_601084 = validateParameter(valid_601084, JString, required = true,
                                 default = nil)
  if valid_601084 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_601084
  var valid_601085 = query.getOrDefault("Action")
  valid_601085 = validateParameter(valid_601085, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_601085 != nil:
    section.add "Action", valid_601085
  var valid_601086 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = nil)
  if valid_601086 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_601086
  var valid_601087 = query.getOrDefault("Version")
  valid_601087 = validateParameter(valid_601087, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601087 != nil:
    section.add "Version", valid_601087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601088 = header.getOrDefault("X-Amz-Date")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Date", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Security-Token")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Security-Token", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601095: Call_GetCopyDBClusterParameterGroup_601079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_601095.validator(path, query, header, formData, body)
  let scheme = call_601095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601095.url(scheme.get, call_601095.host, call_601095.base,
                         call_601095.route, valid.getOrDefault("path"))
  result = hook(call_601095, url, valid)

proc call*(call_601096: Call_GetCopyDBClusterParameterGroup_601079;
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
  var query_601097 = newJObject()
  add(query_601097, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_601097.add "Tags", Tags
  add(query_601097, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_601097, "Action", newJString(Action))
  add(query_601097, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_601097, "Version", newJString(Version))
  result = call_601096.call(nil, query_601097, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_601079(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_601080, base: "/",
    url: url_GetCopyDBClusterParameterGroup_601081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_601139 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBClusterSnapshot_601141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterSnapshot_601140(path: JsonNode; query: JsonNode;
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
  var valid_601142 = query.getOrDefault("Action")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_601142 != nil:
    section.add "Action", valid_601142
  var valid_601143 = query.getOrDefault("Version")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601143 != nil:
    section.add "Version", valid_601143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Content-Sha256", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Algorithm")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Algorithm", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Signature")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Signature", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-SignedHeaders", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Credential")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Credential", valid_601150
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
  var valid_601151 = formData.getOrDefault("PreSignedUrl")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "PreSignedUrl", valid_601151
  var valid_601152 = formData.getOrDefault("Tags")
  valid_601152 = validateParameter(valid_601152, JArray, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "Tags", valid_601152
  var valid_601153 = formData.getOrDefault("CopyTags")
  valid_601153 = validateParameter(valid_601153, JBool, required = false, default = nil)
  if valid_601153 != nil:
    section.add "CopyTags", valid_601153
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_601154 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_601154
  var valid_601155 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = nil)
  if valid_601155 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_601155
  var valid_601156 = formData.getOrDefault("KmsKeyId")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "KmsKeyId", valid_601156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601157: Call_PostCopyDBClusterSnapshot_601139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_601157.validator(path, query, header, formData, body)
  let scheme = call_601157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601157.url(scheme.get, call_601157.host, call_601157.base,
                         call_601157.route, valid.getOrDefault("path"))
  result = hook(call_601157, url, valid)

proc call*(call_601158: Call_PostCopyDBClusterSnapshot_601139;
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
  var query_601159 = newJObject()
  var formData_601160 = newJObject()
  add(formData_601160, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_601160.add "Tags", Tags
  add(formData_601160, "CopyTags", newJBool(CopyTags))
  add(formData_601160, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_601160, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_601159, "Action", newJString(Action))
  add(formData_601160, "KmsKeyId", newJString(KmsKeyId))
  add(query_601159, "Version", newJString(Version))
  result = call_601158.call(nil, query_601159, nil, formData_601160, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_601139(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_601140, base: "/",
    url: url_PostCopyDBClusterSnapshot_601141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_601118 = ref object of OpenApiRestCall_600410
proc url_GetCopyDBClusterSnapshot_601120(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterSnapshot_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = query.getOrDefault("PreSignedUrl")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "PreSignedUrl", valid_601121
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_601122 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_601122
  var valid_601123 = query.getOrDefault("Tags")
  valid_601123 = validateParameter(valid_601123, JArray, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "Tags", valid_601123
  var valid_601124 = query.getOrDefault("Action")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_601124 != nil:
    section.add "Action", valid_601124
  var valid_601125 = query.getOrDefault("KmsKeyId")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "KmsKeyId", valid_601125
  var valid_601126 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_601126
  var valid_601127 = query.getOrDefault("Version")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601127 != nil:
    section.add "Version", valid_601127
  var valid_601128 = query.getOrDefault("CopyTags")
  valid_601128 = validateParameter(valid_601128, JBool, required = false, default = nil)
  if valid_601128 != nil:
    section.add "CopyTags", valid_601128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Content-Sha256", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Algorithm")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Algorithm", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Signature")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Signature", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-SignedHeaders", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Credential")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Credential", valid_601135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601136: Call_GetCopyDBClusterSnapshot_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_601136.validator(path, query, header, formData, body)
  let scheme = call_601136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601136.url(scheme.get, call_601136.host, call_601136.base,
                         call_601136.route, valid.getOrDefault("path"))
  result = hook(call_601136, url, valid)

proc call*(call_601137: Call_GetCopyDBClusterSnapshot_601118;
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
  var query_601138 = newJObject()
  add(query_601138, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_601138, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_601138.add "Tags", Tags
  add(query_601138, "Action", newJString(Action))
  add(query_601138, "KmsKeyId", newJString(KmsKeyId))
  add(query_601138, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_601138, "Version", newJString(Version))
  add(query_601138, "CopyTags", newJBool(CopyTags))
  result = call_601137.call(nil, query_601138, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_601118(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_601119, base: "/",
    url: url_GetCopyDBClusterSnapshot_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_601194 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBCluster_601196(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBCluster_601195(path: JsonNode; query: JsonNode;
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
  var valid_601197 = query.getOrDefault("Action")
  valid_601197 = validateParameter(valid_601197, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_601197 != nil:
    section.add "Action", valid_601197
  var valid_601198 = query.getOrDefault("Version")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601198 != nil:
    section.add "Version", valid_601198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601199 = header.getOrDefault("X-Amz-Date")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Date", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Security-Token")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Security-Token", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Content-Sha256", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Algorithm")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Algorithm", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Signature")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Signature", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-SignedHeaders", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Credential")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Credential", valid_601205
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
  var valid_601206 = formData.getOrDefault("Port")
  valid_601206 = validateParameter(valid_601206, JInt, required = false, default = nil)
  if valid_601206 != nil:
    section.add "Port", valid_601206
  var valid_601207 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601207 = validateParameter(valid_601207, JArray, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "VpcSecurityGroupIds", valid_601207
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601208 = formData.getOrDefault("Engine")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = nil)
  if valid_601208 != nil:
    section.add "Engine", valid_601208
  var valid_601209 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601209 = validateParameter(valid_601209, JInt, required = false, default = nil)
  if valid_601209 != nil:
    section.add "BackupRetentionPeriod", valid_601209
  var valid_601210 = formData.getOrDefault("Tags")
  valid_601210 = validateParameter(valid_601210, JArray, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "Tags", valid_601210
  var valid_601211 = formData.getOrDefault("MasterUserPassword")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "MasterUserPassword", valid_601211
  var valid_601212 = formData.getOrDefault("DeletionProtection")
  valid_601212 = validateParameter(valid_601212, JBool, required = false, default = nil)
  if valid_601212 != nil:
    section.add "DeletionProtection", valid_601212
  var valid_601213 = formData.getOrDefault("DBSubnetGroupName")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "DBSubnetGroupName", valid_601213
  var valid_601214 = formData.getOrDefault("AvailabilityZones")
  valid_601214 = validateParameter(valid_601214, JArray, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "AvailabilityZones", valid_601214
  var valid_601215 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "DBClusterParameterGroupName", valid_601215
  var valid_601216 = formData.getOrDefault("MasterUsername")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "MasterUsername", valid_601216
  var valid_601217 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_601217 = validateParameter(valid_601217, JArray, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601217
  var valid_601218 = formData.getOrDefault("PreferredBackupWindow")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "PreferredBackupWindow", valid_601218
  var valid_601219 = formData.getOrDefault("KmsKeyId")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "KmsKeyId", valid_601219
  var valid_601220 = formData.getOrDefault("StorageEncrypted")
  valid_601220 = validateParameter(valid_601220, JBool, required = false, default = nil)
  if valid_601220 != nil:
    section.add "StorageEncrypted", valid_601220
  var valid_601221 = formData.getOrDefault("DBClusterIdentifier")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "DBClusterIdentifier", valid_601221
  var valid_601222 = formData.getOrDefault("EngineVersion")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "EngineVersion", valid_601222
  var valid_601223 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "PreferredMaintenanceWindow", valid_601223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_PostCreateDBCluster_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_PostCreateDBCluster_601194; Engine: string;
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
  var query_601226 = newJObject()
  var formData_601227 = newJObject()
  add(formData_601227, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_601227.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601227, "Engine", newJString(Engine))
  add(formData_601227, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_601227.add "Tags", Tags
  add(formData_601227, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601227, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_601227, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601226, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_601227.add "AvailabilityZones", AvailabilityZones
  add(formData_601227, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_601227, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_601227.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_601227, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601227, "KmsKeyId", newJString(KmsKeyId))
  add(formData_601227, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_601227, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_601227, "EngineVersion", newJString(EngineVersion))
  add(query_601226, "Version", newJString(Version))
  add(formData_601227, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601225.call(nil, query_601226, nil, formData_601227, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_601194(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_601195, base: "/",
    url: url_PostCreateDBCluster_601196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_601161 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBCluster_601163(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBCluster_601162(path: JsonNode; query: JsonNode;
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
  var valid_601164 = query.getOrDefault("Engine")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "Engine", valid_601164
  var valid_601165 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "PreferredMaintenanceWindow", valid_601165
  var valid_601166 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "DBClusterParameterGroupName", valid_601166
  var valid_601167 = query.getOrDefault("StorageEncrypted")
  valid_601167 = validateParameter(valid_601167, JBool, required = false, default = nil)
  if valid_601167 != nil:
    section.add "StorageEncrypted", valid_601167
  var valid_601168 = query.getOrDefault("AvailabilityZones")
  valid_601168 = validateParameter(valid_601168, JArray, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "AvailabilityZones", valid_601168
  var valid_601169 = query.getOrDefault("DBClusterIdentifier")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "DBClusterIdentifier", valid_601169
  var valid_601170 = query.getOrDefault("MasterUserPassword")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "MasterUserPassword", valid_601170
  var valid_601171 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601171 = validateParameter(valid_601171, JArray, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "VpcSecurityGroupIds", valid_601171
  var valid_601172 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_601172 = validateParameter(valid_601172, JArray, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601172
  var valid_601173 = query.getOrDefault("Tags")
  valid_601173 = validateParameter(valid_601173, JArray, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "Tags", valid_601173
  var valid_601174 = query.getOrDefault("BackupRetentionPeriod")
  valid_601174 = validateParameter(valid_601174, JInt, required = false, default = nil)
  if valid_601174 != nil:
    section.add "BackupRetentionPeriod", valid_601174
  var valid_601175 = query.getOrDefault("DeletionProtection")
  valid_601175 = validateParameter(valid_601175, JBool, required = false, default = nil)
  if valid_601175 != nil:
    section.add "DeletionProtection", valid_601175
  var valid_601176 = query.getOrDefault("Action")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_601176 != nil:
    section.add "Action", valid_601176
  var valid_601177 = query.getOrDefault("DBSubnetGroupName")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "DBSubnetGroupName", valid_601177
  var valid_601178 = query.getOrDefault("KmsKeyId")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "KmsKeyId", valid_601178
  var valid_601179 = query.getOrDefault("EngineVersion")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "EngineVersion", valid_601179
  var valid_601180 = query.getOrDefault("Port")
  valid_601180 = validateParameter(valid_601180, JInt, required = false, default = nil)
  if valid_601180 != nil:
    section.add "Port", valid_601180
  var valid_601181 = query.getOrDefault("PreferredBackupWindow")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "PreferredBackupWindow", valid_601181
  var valid_601182 = query.getOrDefault("Version")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601182 != nil:
    section.add "Version", valid_601182
  var valid_601183 = query.getOrDefault("MasterUsername")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "MasterUsername", valid_601183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601184 = header.getOrDefault("X-Amz-Date")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Date", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Security-Token")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Security-Token", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Content-Sha256", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Algorithm")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Algorithm", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Signature")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Signature", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-SignedHeaders", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Credential")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Credential", valid_601190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_GetCreateDBCluster_601161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_GetCreateDBCluster_601161; Engine: string;
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
  var query_601193 = newJObject()
  add(query_601193, "Engine", newJString(Engine))
  add(query_601193, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601193, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601193, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_601193.add "AvailabilityZones", AvailabilityZones
  add(query_601193, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601193, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_601193.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_601193.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_601193.add "Tags", Tags
  add(query_601193, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601193, "DeletionProtection", newJBool(DeletionProtection))
  add(query_601193, "Action", newJString(Action))
  add(query_601193, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601193, "KmsKeyId", newJString(KmsKeyId))
  add(query_601193, "EngineVersion", newJString(EngineVersion))
  add(query_601193, "Port", newJInt(Port))
  add(query_601193, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601193, "Version", newJString(Version))
  add(query_601193, "MasterUsername", newJString(MasterUsername))
  result = call_601192.call(nil, query_601193, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_601161(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_601162,
    base: "/", url: url_GetCreateDBCluster_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_601247 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBClusterParameterGroup_601249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterParameterGroup_601248(path: JsonNode;
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
  var valid_601250 = query.getOrDefault("Action")
  valid_601250 = validateParameter(valid_601250, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_601250 != nil:
    section.add "Action", valid_601250
  var valid_601251 = query.getOrDefault("Version")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601251 != nil:
    section.add "Version", valid_601251
  result.add "query", section
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
  var valid_601259 = formData.getOrDefault("Tags")
  valid_601259 = validateParameter(valid_601259, JArray, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "Tags", valid_601259
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601260 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = nil)
  if valid_601260 != nil:
    section.add "DBClusterParameterGroupName", valid_601260
  var valid_601261 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "DBParameterGroupFamily", valid_601261
  var valid_601262 = formData.getOrDefault("Description")
  valid_601262 = validateParameter(valid_601262, JString, required = true,
                                 default = nil)
  if valid_601262 != nil:
    section.add "Description", valid_601262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601263: Call_PostCreateDBClusterParameterGroup_601247;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_601263.validator(path, query, header, formData, body)
  let scheme = call_601263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601263.url(scheme.get, call_601263.host, call_601263.base,
                         call_601263.route, valid.getOrDefault("path"))
  result = hook(call_601263, url, valid)

proc call*(call_601264: Call_PostCreateDBClusterParameterGroup_601247;
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
  var query_601265 = newJObject()
  var formData_601266 = newJObject()
  if Tags != nil:
    formData_601266.add "Tags", Tags
  add(query_601265, "Action", newJString(Action))
  add(formData_601266, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_601266, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601265, "Version", newJString(Version))
  add(formData_601266, "Description", newJString(Description))
  result = call_601264.call(nil, query_601265, nil, formData_601266, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_601247(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_601248, base: "/",
    url: url_PostCreateDBClusterParameterGroup_601249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_601228 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBClusterParameterGroup_601230(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterParameterGroup_601229(path: JsonNode;
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
  var valid_601231 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "DBClusterParameterGroupName", valid_601231
  var valid_601232 = query.getOrDefault("Description")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "Description", valid_601232
  var valid_601233 = query.getOrDefault("DBParameterGroupFamily")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "DBParameterGroupFamily", valid_601233
  var valid_601234 = query.getOrDefault("Tags")
  valid_601234 = validateParameter(valid_601234, JArray, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "Tags", valid_601234
  var valid_601235 = query.getOrDefault("Action")
  valid_601235 = validateParameter(valid_601235, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_601235 != nil:
    section.add "Action", valid_601235
  var valid_601236 = query.getOrDefault("Version")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601236 != nil:
    section.add "Version", valid_601236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601237 = header.getOrDefault("X-Amz-Date")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Date", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Security-Token")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Security-Token", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Content-Sha256", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Algorithm")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Algorithm", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Signature")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Signature", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-SignedHeaders", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Credential")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Credential", valid_601243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_GetCreateDBClusterParameterGroup_601228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_GetCreateDBClusterParameterGroup_601228;
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
  var query_601246 = newJObject()
  add(query_601246, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601246, "Description", newJString(Description))
  add(query_601246, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_601246.add "Tags", Tags
  add(query_601246, "Action", newJString(Action))
  add(query_601246, "Version", newJString(Version))
  result = call_601245.call(nil, query_601246, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_601228(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_601229, base: "/",
    url: url_GetCreateDBClusterParameterGroup_601230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_601285 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBClusterSnapshot_601287(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterSnapshot_601286(path: JsonNode; query: JsonNode;
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
  var valid_601288 = query.getOrDefault("Action")
  valid_601288 = validateParameter(valid_601288, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_601288 != nil:
    section.add "Action", valid_601288
  var valid_601289 = query.getOrDefault("Version")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601289 != nil:
    section.add "Version", valid_601289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601290 = header.getOrDefault("X-Amz-Date")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Date", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Security-Token")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Security-Token", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Content-Sha256", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Algorithm")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Algorithm", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Signature")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Signature", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-SignedHeaders", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Credential")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Credential", valid_601296
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
  var valid_601297 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601297 = validateParameter(valid_601297, JString, required = true,
                                 default = nil)
  if valid_601297 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601297
  var valid_601298 = formData.getOrDefault("Tags")
  valid_601298 = validateParameter(valid_601298, JArray, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "Tags", valid_601298
  var valid_601299 = formData.getOrDefault("DBClusterIdentifier")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = nil)
  if valid_601299 != nil:
    section.add "DBClusterIdentifier", valid_601299
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601300: Call_PostCreateDBClusterSnapshot_601285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_601300.validator(path, query, header, formData, body)
  let scheme = call_601300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601300.url(scheme.get, call_601300.host, call_601300.base,
                         call_601300.route, valid.getOrDefault("path"))
  result = hook(call_601300, url, valid)

proc call*(call_601301: Call_PostCreateDBClusterSnapshot_601285;
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
  var query_601302 = newJObject()
  var formData_601303 = newJObject()
  add(formData_601303, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_601303.add "Tags", Tags
  add(query_601302, "Action", newJString(Action))
  add(formData_601303, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601302, "Version", newJString(Version))
  result = call_601301.call(nil, query_601302, nil, formData_601303, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_601285(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_601286, base: "/",
    url: url_PostCreateDBClusterSnapshot_601287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_601267 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBClusterSnapshot_601269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterSnapshot_601268(path: JsonNode; query: JsonNode;
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
  var valid_601270 = query.getOrDefault("DBClusterIdentifier")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = nil)
  if valid_601270 != nil:
    section.add "DBClusterIdentifier", valid_601270
  var valid_601271 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = nil)
  if valid_601271 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601271
  var valid_601272 = query.getOrDefault("Tags")
  valid_601272 = validateParameter(valid_601272, JArray, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "Tags", valid_601272
  var valid_601273 = query.getOrDefault("Action")
  valid_601273 = validateParameter(valid_601273, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_601273 != nil:
    section.add "Action", valid_601273
  var valid_601274 = query.getOrDefault("Version")
  valid_601274 = validateParameter(valid_601274, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601274 != nil:
    section.add "Version", valid_601274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601275 = header.getOrDefault("X-Amz-Date")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Date", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Security-Token")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Security-Token", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Content-Sha256", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Algorithm")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Algorithm", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Signature")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Signature", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-SignedHeaders", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Credential")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Credential", valid_601281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601282: Call_GetCreateDBClusterSnapshot_601267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_601282.validator(path, query, header, formData, body)
  let scheme = call_601282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601282.url(scheme.get, call_601282.host, call_601282.base,
                         call_601282.route, valid.getOrDefault("path"))
  result = hook(call_601282, url, valid)

proc call*(call_601283: Call_GetCreateDBClusterSnapshot_601267;
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
  var query_601284 = newJObject()
  add(query_601284, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601284, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_601284.add "Tags", Tags
  add(query_601284, "Action", newJString(Action))
  add(query_601284, "Version", newJString(Version))
  result = call_601283.call(nil, query_601284, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_601267(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_601268, base: "/",
    url: url_GetCreateDBClusterSnapshot_601269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601328 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstance_601330(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_601329(path: JsonNode; query: JsonNode;
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
  var valid_601331 = query.getOrDefault("Action")
  valid_601331 = validateParameter(valid_601331, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601331 != nil:
    section.add "Action", valid_601331
  var valid_601332 = query.getOrDefault("Version")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601332 != nil:
    section.add "Version", valid_601332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601333 = header.getOrDefault("X-Amz-Date")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Date", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Security-Token")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Security-Token", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Content-Sha256", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Algorithm")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Algorithm", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Signature")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Signature", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-SignedHeaders", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Credential")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Credential", valid_601339
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
  var valid_601340 = formData.getOrDefault("Engine")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = nil)
  if valid_601340 != nil:
    section.add "Engine", valid_601340
  var valid_601341 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601341 = validateParameter(valid_601341, JString, required = true,
                                 default = nil)
  if valid_601341 != nil:
    section.add "DBInstanceIdentifier", valid_601341
  var valid_601342 = formData.getOrDefault("Tags")
  valid_601342 = validateParameter(valid_601342, JArray, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "Tags", valid_601342
  var valid_601343 = formData.getOrDefault("AvailabilityZone")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "AvailabilityZone", valid_601343
  var valid_601344 = formData.getOrDefault("PromotionTier")
  valid_601344 = validateParameter(valid_601344, JInt, required = false, default = nil)
  if valid_601344 != nil:
    section.add "PromotionTier", valid_601344
  var valid_601345 = formData.getOrDefault("DBInstanceClass")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = nil)
  if valid_601345 != nil:
    section.add "DBInstanceClass", valid_601345
  var valid_601346 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601346 = validateParameter(valid_601346, JBool, required = false, default = nil)
  if valid_601346 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601346
  var valid_601347 = formData.getOrDefault("DBClusterIdentifier")
  valid_601347 = validateParameter(valid_601347, JString, required = true,
                                 default = nil)
  if valid_601347 != nil:
    section.add "DBClusterIdentifier", valid_601347
  var valid_601348 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "PreferredMaintenanceWindow", valid_601348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_PostCreateDBInstance_601328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_PostCreateDBInstance_601328; Engine: string;
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
  var query_601351 = newJObject()
  var formData_601352 = newJObject()
  add(formData_601352, "Engine", newJString(Engine))
  add(formData_601352, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_601352.add "Tags", Tags
  add(formData_601352, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601351, "Action", newJString(Action))
  add(formData_601352, "PromotionTier", newJInt(PromotionTier))
  add(formData_601352, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601352, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601352, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601351, "Version", newJString(Version))
  add(formData_601352, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601350.call(nil, query_601351, nil, formData_601352, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601328(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601329, base: "/",
    url: url_PostCreateDBInstance_601330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601304 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstance_601306(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_601305(path: JsonNode; query: JsonNode;
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
  var valid_601307 = query.getOrDefault("Engine")
  valid_601307 = validateParameter(valid_601307, JString, required = true,
                                 default = nil)
  if valid_601307 != nil:
    section.add "Engine", valid_601307
  var valid_601308 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "PreferredMaintenanceWindow", valid_601308
  var valid_601309 = query.getOrDefault("PromotionTier")
  valid_601309 = validateParameter(valid_601309, JInt, required = false, default = nil)
  if valid_601309 != nil:
    section.add "PromotionTier", valid_601309
  var valid_601310 = query.getOrDefault("DBClusterIdentifier")
  valid_601310 = validateParameter(valid_601310, JString, required = true,
                                 default = nil)
  if valid_601310 != nil:
    section.add "DBClusterIdentifier", valid_601310
  var valid_601311 = query.getOrDefault("AvailabilityZone")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "AvailabilityZone", valid_601311
  var valid_601312 = query.getOrDefault("Tags")
  valid_601312 = validateParameter(valid_601312, JArray, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "Tags", valid_601312
  var valid_601313 = query.getOrDefault("DBInstanceClass")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "DBInstanceClass", valid_601313
  var valid_601314 = query.getOrDefault("Action")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601314 != nil:
    section.add "Action", valid_601314
  var valid_601315 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601315 = validateParameter(valid_601315, JBool, required = false, default = nil)
  if valid_601315 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601315
  var valid_601316 = query.getOrDefault("Version")
  valid_601316 = validateParameter(valid_601316, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601316 != nil:
    section.add "Version", valid_601316
  var valid_601317 = query.getOrDefault("DBInstanceIdentifier")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = nil)
  if valid_601317 != nil:
    section.add "DBInstanceIdentifier", valid_601317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601318 = header.getOrDefault("X-Amz-Date")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Date", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Security-Token")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Security-Token", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Content-Sha256", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Algorithm")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Algorithm", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Signature")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Signature", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-SignedHeaders", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Credential")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Credential", valid_601324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601325: Call_GetCreateDBInstance_601304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_601325.validator(path, query, header, formData, body)
  let scheme = call_601325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601325.url(scheme.get, call_601325.host, call_601325.base,
                         call_601325.route, valid.getOrDefault("path"))
  result = hook(call_601325, url, valid)

proc call*(call_601326: Call_GetCreateDBInstance_601304; Engine: string;
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
  var query_601327 = newJObject()
  add(query_601327, "Engine", newJString(Engine))
  add(query_601327, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601327, "PromotionTier", newJInt(PromotionTier))
  add(query_601327, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601327, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_601327.add "Tags", Tags
  add(query_601327, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601327, "Action", newJString(Action))
  add(query_601327, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601327, "Version", newJString(Version))
  add(query_601327, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601326.call(nil, query_601327, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601304(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601305, base: "/",
    url: url_GetCreateDBInstance_601306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601372 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSubnetGroup_601374(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_601373(path: JsonNode; query: JsonNode;
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
  var valid_601375 = query.getOrDefault("Action")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601375 != nil:
    section.add "Action", valid_601375
  var valid_601376 = query.getOrDefault("Version")
  valid_601376 = validateParameter(valid_601376, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601376 != nil:
    section.add "Version", valid_601376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601377 = header.getOrDefault("X-Amz-Date")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Date", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Security-Token")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Security-Token", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
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
  var valid_601384 = formData.getOrDefault("Tags")
  valid_601384 = validateParameter(valid_601384, JArray, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "Tags", valid_601384
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601385 = formData.getOrDefault("DBSubnetGroupName")
  valid_601385 = validateParameter(valid_601385, JString, required = true,
                                 default = nil)
  if valid_601385 != nil:
    section.add "DBSubnetGroupName", valid_601385
  var valid_601386 = formData.getOrDefault("SubnetIds")
  valid_601386 = validateParameter(valid_601386, JArray, required = true, default = nil)
  if valid_601386 != nil:
    section.add "SubnetIds", valid_601386
  var valid_601387 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601387 = validateParameter(valid_601387, JString, required = true,
                                 default = nil)
  if valid_601387 != nil:
    section.add "DBSubnetGroupDescription", valid_601387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601388: Call_PostCreateDBSubnetGroup_601372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_601388.validator(path, query, header, formData, body)
  let scheme = call_601388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601388.url(scheme.get, call_601388.host, call_601388.base,
                         call_601388.route, valid.getOrDefault("path"))
  result = hook(call_601388, url, valid)

proc call*(call_601389: Call_PostCreateDBSubnetGroup_601372;
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
  var query_601390 = newJObject()
  var formData_601391 = newJObject()
  if Tags != nil:
    formData_601391.add "Tags", Tags
  add(formData_601391, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601391.add "SubnetIds", SubnetIds
  add(query_601390, "Action", newJString(Action))
  add(formData_601391, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601390, "Version", newJString(Version))
  result = call_601389.call(nil, query_601390, nil, formData_601391, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601372(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601373, base: "/",
    url: url_PostCreateDBSubnetGroup_601374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601353 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSubnetGroup_601355(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_601354(path: JsonNode; query: JsonNode;
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
  var valid_601356 = query.getOrDefault("Tags")
  valid_601356 = validateParameter(valid_601356, JArray, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "Tags", valid_601356
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601357 = query.getOrDefault("Action")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601357 != nil:
    section.add "Action", valid_601357
  var valid_601358 = query.getOrDefault("DBSubnetGroupName")
  valid_601358 = validateParameter(valid_601358, JString, required = true,
                                 default = nil)
  if valid_601358 != nil:
    section.add "DBSubnetGroupName", valid_601358
  var valid_601359 = query.getOrDefault("SubnetIds")
  valid_601359 = validateParameter(valid_601359, JArray, required = true, default = nil)
  if valid_601359 != nil:
    section.add "SubnetIds", valid_601359
  var valid_601360 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = nil)
  if valid_601360 != nil:
    section.add "DBSubnetGroupDescription", valid_601360
  var valid_601361 = query.getOrDefault("Version")
  valid_601361 = validateParameter(valid_601361, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601361 != nil:
    section.add "Version", valid_601361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Content-Sha256", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Algorithm")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Algorithm", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Signature")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Signature", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-SignedHeaders", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Credential")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Credential", valid_601368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601369: Call_GetCreateDBSubnetGroup_601353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_601369.validator(path, query, header, formData, body)
  let scheme = call_601369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601369.url(scheme.get, call_601369.host, call_601369.base,
                         call_601369.route, valid.getOrDefault("path"))
  result = hook(call_601369, url, valid)

proc call*(call_601370: Call_GetCreateDBSubnetGroup_601353;
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
  var query_601371 = newJObject()
  if Tags != nil:
    query_601371.add "Tags", Tags
  add(query_601371, "Action", newJString(Action))
  add(query_601371, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601371.add "SubnetIds", SubnetIds
  add(query_601371, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601371, "Version", newJString(Version))
  result = call_601370.call(nil, query_601371, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601353(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601354, base: "/",
    url: url_GetCreateDBSubnetGroup_601355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_601410 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBCluster_601412(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBCluster_601411(path: JsonNode; query: JsonNode;
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
  var valid_601413 = query.getOrDefault("Action")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_601413 != nil:
    section.add "Action", valid_601413
  var valid_601414 = query.getOrDefault("Version")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601414 != nil:
    section.add "Version", valid_601414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_601422 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601422
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601423 = formData.getOrDefault("DBClusterIdentifier")
  valid_601423 = validateParameter(valid_601423, JString, required = true,
                                 default = nil)
  if valid_601423 != nil:
    section.add "DBClusterIdentifier", valid_601423
  var valid_601424 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601424 = validateParameter(valid_601424, JBool, required = false, default = nil)
  if valid_601424 != nil:
    section.add "SkipFinalSnapshot", valid_601424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601425: Call_PostDeleteDBCluster_601410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_601425.validator(path, query, header, formData, body)
  let scheme = call_601425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601425.url(scheme.get, call_601425.host, call_601425.base,
                         call_601425.route, valid.getOrDefault("path"))
  result = hook(call_601425, url, valid)

proc call*(call_601426: Call_PostDeleteDBCluster_601410;
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
  var query_601427 = newJObject()
  var formData_601428 = newJObject()
  add(formData_601428, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601427, "Action", newJString(Action))
  add(formData_601428, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601427, "Version", newJString(Version))
  add(formData_601428, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601426.call(nil, query_601427, nil, formData_601428, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_601410(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_601411, base: "/",
    url: url_PostDeleteDBCluster_601412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_601392 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBCluster_601394(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBCluster_601393(path: JsonNode; query: JsonNode;
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
  var valid_601395 = query.getOrDefault("DBClusterIdentifier")
  valid_601395 = validateParameter(valid_601395, JString, required = true,
                                 default = nil)
  if valid_601395 != nil:
    section.add "DBClusterIdentifier", valid_601395
  var valid_601396 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601396
  var valid_601397 = query.getOrDefault("Action")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_601397 != nil:
    section.add "Action", valid_601397
  var valid_601398 = query.getOrDefault("SkipFinalSnapshot")
  valid_601398 = validateParameter(valid_601398, JBool, required = false, default = nil)
  if valid_601398 != nil:
    section.add "SkipFinalSnapshot", valid_601398
  var valid_601399 = query.getOrDefault("Version")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601399 != nil:
    section.add "Version", valid_601399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Content-Sha256", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Algorithm")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Algorithm", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Signature")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Signature", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-SignedHeaders", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Credential")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Credential", valid_601406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601407: Call_GetDeleteDBCluster_601392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_601407.validator(path, query, header, formData, body)
  let scheme = call_601407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601407.url(scheme.get, call_601407.host, call_601407.base,
                         call_601407.route, valid.getOrDefault("path"))
  result = hook(call_601407, url, valid)

proc call*(call_601408: Call_GetDeleteDBCluster_601392;
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
  var query_601409 = newJObject()
  add(query_601409, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601409, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601409, "Action", newJString(Action))
  add(query_601409, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601409, "Version", newJString(Version))
  result = call_601408.call(nil, query_601409, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_601392(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_601393,
    base: "/", url: url_GetDeleteDBCluster_601394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_601445 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBClusterParameterGroup_601447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterParameterGroup_601446(path: JsonNode;
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
  var valid_601448 = query.getOrDefault("Action")
  valid_601448 = validateParameter(valid_601448, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_601448 != nil:
    section.add "Action", valid_601448
  var valid_601449 = query.getOrDefault("Version")
  valid_601449 = validateParameter(valid_601449, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601449 != nil:
    section.add "Version", valid_601449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601450 = header.getOrDefault("X-Amz-Date")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Date", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Security-Token")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Security-Token", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Content-Sha256", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Algorithm")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Algorithm", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Signature")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Signature", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-SignedHeaders", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Credential")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Credential", valid_601456
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601457 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601457 = validateParameter(valid_601457, JString, required = true,
                                 default = nil)
  if valid_601457 != nil:
    section.add "DBClusterParameterGroupName", valid_601457
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_PostDeleteDBClusterParameterGroup_601445;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_PostDeleteDBClusterParameterGroup_601445;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_601460 = newJObject()
  var formData_601461 = newJObject()
  add(query_601460, "Action", newJString(Action))
  add(formData_601461, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601460, "Version", newJString(Version))
  result = call_601459.call(nil, query_601460, nil, formData_601461, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_601445(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_601446, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_601447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_601429 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBClusterParameterGroup_601431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterParameterGroup_601430(path: JsonNode;
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
  var valid_601432 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601432 = validateParameter(valid_601432, JString, required = true,
                                 default = nil)
  if valid_601432 != nil:
    section.add "DBClusterParameterGroupName", valid_601432
  var valid_601433 = query.getOrDefault("Action")
  valid_601433 = validateParameter(valid_601433, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_601433 != nil:
    section.add "Action", valid_601433
  var valid_601434 = query.getOrDefault("Version")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601434 != nil:
    section.add "Version", valid_601434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601435 = header.getOrDefault("X-Amz-Date")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Date", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Security-Token")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Security-Token", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601442: Call_GetDeleteDBClusterParameterGroup_601429;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_601442.validator(path, query, header, formData, body)
  let scheme = call_601442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601442.url(scheme.get, call_601442.host, call_601442.base,
                         call_601442.route, valid.getOrDefault("path"))
  result = hook(call_601442, url, valid)

proc call*(call_601443: Call_GetDeleteDBClusterParameterGroup_601429;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601444 = newJObject()
  add(query_601444, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601444, "Action", newJString(Action))
  add(query_601444, "Version", newJString(Version))
  result = call_601443.call(nil, query_601444, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_601429(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_601430, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_601431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_601478 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBClusterSnapshot_601480(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterSnapshot_601479(path: JsonNode; query: JsonNode;
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
  var valid_601481 = query.getOrDefault("Action")
  valid_601481 = validateParameter(valid_601481, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_601481 != nil:
    section.add "Action", valid_601481
  var valid_601482 = query.getOrDefault("Version")
  valid_601482 = validateParameter(valid_601482, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601482 != nil:
    section.add "Version", valid_601482
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_601490 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601490 = validateParameter(valid_601490, JString, required = true,
                                 default = nil)
  if valid_601490 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601490
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_PostDeleteDBClusterSnapshot_601478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_PostDeleteDBClusterSnapshot_601478;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601493 = newJObject()
  var formData_601494 = newJObject()
  add(formData_601494, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_601493, "Action", newJString(Action))
  add(query_601493, "Version", newJString(Version))
  result = call_601492.call(nil, query_601493, nil, formData_601494, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_601478(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_601479, base: "/",
    url: url_PostDeleteDBClusterSnapshot_601480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_601462 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBClusterSnapshot_601464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterSnapshot_601463(path: JsonNode; query: JsonNode;
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
  var valid_601465 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601465 = validateParameter(valid_601465, JString, required = true,
                                 default = nil)
  if valid_601465 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601465
  var valid_601466 = query.getOrDefault("Action")
  valid_601466 = validateParameter(valid_601466, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_601466 != nil:
    section.add "Action", valid_601466
  var valid_601467 = query.getOrDefault("Version")
  valid_601467 = validateParameter(valid_601467, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601467 != nil:
    section.add "Version", valid_601467
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601468 = header.getOrDefault("X-Amz-Date")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Date", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Security-Token")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Security-Token", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Content-Sha256", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Algorithm")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Algorithm", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Signature")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Signature", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-SignedHeaders", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Credential")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Credential", valid_601474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601475: Call_GetDeleteDBClusterSnapshot_601462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_601475.validator(path, query, header, formData, body)
  let scheme = call_601475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601475.url(scheme.get, call_601475.host, call_601475.base,
                         call_601475.route, valid.getOrDefault("path"))
  result = hook(call_601475, url, valid)

proc call*(call_601476: Call_GetDeleteDBClusterSnapshot_601462;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601477 = newJObject()
  add(query_601477, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_601477, "Action", newJString(Action))
  add(query_601477, "Version", newJString(Version))
  result = call_601476.call(nil, query_601477, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_601462(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_601463, base: "/",
    url: url_GetDeleteDBClusterSnapshot_601464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601511 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBInstance_601513(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_601512(path: JsonNode; query: JsonNode;
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
  var valid_601514 = query.getOrDefault("Action")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601514 != nil:
    section.add "Action", valid_601514
  var valid_601515 = query.getOrDefault("Version")
  valid_601515 = validateParameter(valid_601515, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601515 != nil:
    section.add "Version", valid_601515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601516 = header.getOrDefault("X-Amz-Date")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Date", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Security-Token")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Security-Token", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Content-Sha256", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Algorithm")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Algorithm", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Signature")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Signature", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-SignedHeaders", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Credential")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Credential", valid_601522
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601523 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601523 = validateParameter(valid_601523, JString, required = true,
                                 default = nil)
  if valid_601523 != nil:
    section.add "DBInstanceIdentifier", valid_601523
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601524: Call_PostDeleteDBInstance_601511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_601524.validator(path, query, header, formData, body)
  let scheme = call_601524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601524.url(scheme.get, call_601524.host, call_601524.base,
                         call_601524.route, valid.getOrDefault("path"))
  result = hook(call_601524, url, valid)

proc call*(call_601525: Call_PostDeleteDBInstance_601511;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601526 = newJObject()
  var formData_601527 = newJObject()
  add(formData_601527, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601526, "Action", newJString(Action))
  add(query_601526, "Version", newJString(Version))
  result = call_601525.call(nil, query_601526, nil, formData_601527, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601511(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601512, base: "/",
    url: url_PostDeleteDBInstance_601513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601495 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBInstance_601497(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_601496(path: JsonNode; query: JsonNode;
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
  var valid_601498 = query.getOrDefault("Action")
  valid_601498 = validateParameter(valid_601498, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601498 != nil:
    section.add "Action", valid_601498
  var valid_601499 = query.getOrDefault("Version")
  valid_601499 = validateParameter(valid_601499, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601499 != nil:
    section.add "Version", valid_601499
  var valid_601500 = query.getOrDefault("DBInstanceIdentifier")
  valid_601500 = validateParameter(valid_601500, JString, required = true,
                                 default = nil)
  if valid_601500 != nil:
    section.add "DBInstanceIdentifier", valid_601500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601501 = header.getOrDefault("X-Amz-Date")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Date", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Security-Token")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Security-Token", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Content-Sha256", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Algorithm")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Algorithm", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Signature")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Signature", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-SignedHeaders", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Credential")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Credential", valid_601507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601508: Call_GetDeleteDBInstance_601495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_601508.validator(path, query, header, formData, body)
  let scheme = call_601508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601508.url(scheme.get, call_601508.host, call_601508.base,
                         call_601508.route, valid.getOrDefault("path"))
  result = hook(call_601508, url, valid)

proc call*(call_601509: Call_GetDeleteDBInstance_601495;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_601510 = newJObject()
  add(query_601510, "Action", newJString(Action))
  add(query_601510, "Version", newJString(Version))
  add(query_601510, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601509.call(nil, query_601510, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601495(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601496, base: "/",
    url: url_GetDeleteDBInstance_601497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601544 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSubnetGroup_601546(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_601545(path: JsonNode; query: JsonNode;
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
  var valid_601547 = query.getOrDefault("Action")
  valid_601547 = validateParameter(valid_601547, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601547 != nil:
    section.add "Action", valid_601547
  var valid_601548 = query.getOrDefault("Version")
  valid_601548 = validateParameter(valid_601548, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601548 != nil:
    section.add "Version", valid_601548
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601549 = header.getOrDefault("X-Amz-Date")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Date", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Security-Token")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Security-Token", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Content-Sha256", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Algorithm")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Algorithm", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Signature")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Signature", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-SignedHeaders", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Credential")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Credential", valid_601555
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601556 = formData.getOrDefault("DBSubnetGroupName")
  valid_601556 = validateParameter(valid_601556, JString, required = true,
                                 default = nil)
  if valid_601556 != nil:
    section.add "DBSubnetGroupName", valid_601556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_PostDeleteDBSubnetGroup_601544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_PostDeleteDBSubnetGroup_601544;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601559 = newJObject()
  var formData_601560 = newJObject()
  add(formData_601560, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601559, "Action", newJString(Action))
  add(query_601559, "Version", newJString(Version))
  result = call_601558.call(nil, query_601559, nil, formData_601560, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601544(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601545, base: "/",
    url: url_PostDeleteDBSubnetGroup_601546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601528 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSubnetGroup_601530(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_601529(path: JsonNode; query: JsonNode;
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
  var valid_601531 = query.getOrDefault("Action")
  valid_601531 = validateParameter(valid_601531, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601531 != nil:
    section.add "Action", valid_601531
  var valid_601532 = query.getOrDefault("DBSubnetGroupName")
  valid_601532 = validateParameter(valid_601532, JString, required = true,
                                 default = nil)
  if valid_601532 != nil:
    section.add "DBSubnetGroupName", valid_601532
  var valid_601533 = query.getOrDefault("Version")
  valid_601533 = validateParameter(valid_601533, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601533 != nil:
    section.add "Version", valid_601533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601534 = header.getOrDefault("X-Amz-Date")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Date", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Security-Token")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Security-Token", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Content-Sha256", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Algorithm")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Algorithm", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Signature")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Signature", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-SignedHeaders", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Credential")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Credential", valid_601540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601541: Call_GetDeleteDBSubnetGroup_601528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_601541.validator(path, query, header, formData, body)
  let scheme = call_601541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601541.url(scheme.get, call_601541.host, call_601541.base,
                         call_601541.route, valid.getOrDefault("path"))
  result = hook(call_601541, url, valid)

proc call*(call_601542: Call_GetDeleteDBSubnetGroup_601528;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_601543 = newJObject()
  add(query_601543, "Action", newJString(Action))
  add(query_601543, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601543, "Version", newJString(Version))
  result = call_601542.call(nil, query_601543, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601528(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601529, base: "/",
    url: url_GetDeleteDBSubnetGroup_601530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_601580 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBClusterParameterGroups_601582(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameterGroups_601581(path: JsonNode;
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
  var valid_601583 = query.getOrDefault("Action")
  valid_601583 = validateParameter(valid_601583, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_601583 != nil:
    section.add "Action", valid_601583
  var valid_601584 = query.getOrDefault("Version")
  valid_601584 = validateParameter(valid_601584, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601584 != nil:
    section.add "Version", valid_601584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601585 = header.getOrDefault("X-Amz-Date")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Date", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Security-Token")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Security-Token", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Content-Sha256", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Algorithm")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Algorithm", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Signature")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Signature", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-SignedHeaders", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Credential")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Credential", valid_601591
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
  var valid_601592 = formData.getOrDefault("Marker")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "Marker", valid_601592
  var valid_601593 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "DBClusterParameterGroupName", valid_601593
  var valid_601594 = formData.getOrDefault("Filters")
  valid_601594 = validateParameter(valid_601594, JArray, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "Filters", valid_601594
  var valid_601595 = formData.getOrDefault("MaxRecords")
  valid_601595 = validateParameter(valid_601595, JInt, required = false, default = nil)
  if valid_601595 != nil:
    section.add "MaxRecords", valid_601595
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_PostDescribeDBClusterParameterGroups_601580;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_PostDescribeDBClusterParameterGroups_601580;
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
  var query_601598 = newJObject()
  var formData_601599 = newJObject()
  add(formData_601599, "Marker", newJString(Marker))
  add(query_601598, "Action", newJString(Action))
  add(formData_601599, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_601599.add "Filters", Filters
  add(formData_601599, "MaxRecords", newJInt(MaxRecords))
  add(query_601598, "Version", newJString(Version))
  result = call_601597.call(nil, query_601598, nil, formData_601599, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_601580(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_601581, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_601582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_601561 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBClusterParameterGroups_601563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameterGroups_601562(path: JsonNode;
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
  var valid_601564 = query.getOrDefault("MaxRecords")
  valid_601564 = validateParameter(valid_601564, JInt, required = false, default = nil)
  if valid_601564 != nil:
    section.add "MaxRecords", valid_601564
  var valid_601565 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "DBClusterParameterGroupName", valid_601565
  var valid_601566 = query.getOrDefault("Filters")
  valid_601566 = validateParameter(valid_601566, JArray, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "Filters", valid_601566
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601567 = query.getOrDefault("Action")
  valid_601567 = validateParameter(valid_601567, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_601567 != nil:
    section.add "Action", valid_601567
  var valid_601568 = query.getOrDefault("Marker")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "Marker", valid_601568
  var valid_601569 = query.getOrDefault("Version")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601569 != nil:
    section.add "Version", valid_601569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601570 = header.getOrDefault("X-Amz-Date")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Date", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Security-Token")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Security-Token", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Content-Sha256", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Algorithm")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Algorithm", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Signature")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Signature", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-SignedHeaders", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Credential")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Credential", valid_601576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601577: Call_GetDescribeDBClusterParameterGroups_601561;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_601577.validator(path, query, header, formData, body)
  let scheme = call_601577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601577.url(scheme.get, call_601577.host, call_601577.base,
                         call_601577.route, valid.getOrDefault("path"))
  result = hook(call_601577, url, valid)

proc call*(call_601578: Call_GetDescribeDBClusterParameterGroups_601561;
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
  var query_601579 = newJObject()
  add(query_601579, "MaxRecords", newJInt(MaxRecords))
  add(query_601579, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_601579.add "Filters", Filters
  add(query_601579, "Action", newJString(Action))
  add(query_601579, "Marker", newJString(Marker))
  add(query_601579, "Version", newJString(Version))
  result = call_601578.call(nil, query_601579, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_601561(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_601562, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_601563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_601620 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBClusterParameters_601622(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameters_601621(path: JsonNode;
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
  var valid_601623 = query.getOrDefault("Action")
  valid_601623 = validateParameter(valid_601623, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_601623 != nil:
    section.add "Action", valid_601623
  var valid_601624 = query.getOrDefault("Version")
  valid_601624 = validateParameter(valid_601624, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601624 != nil:
    section.add "Version", valid_601624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601625 = header.getOrDefault("X-Amz-Date")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Date", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Security-Token")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Security-Token", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Content-Sha256", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Algorithm")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Algorithm", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Signature")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Signature", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-SignedHeaders", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Credential")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Credential", valid_601631
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
  var valid_601632 = formData.getOrDefault("Marker")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "Marker", valid_601632
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601633 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601633 = validateParameter(valid_601633, JString, required = true,
                                 default = nil)
  if valid_601633 != nil:
    section.add "DBClusterParameterGroupName", valid_601633
  var valid_601634 = formData.getOrDefault("Filters")
  valid_601634 = validateParameter(valid_601634, JArray, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "Filters", valid_601634
  var valid_601635 = formData.getOrDefault("MaxRecords")
  valid_601635 = validateParameter(valid_601635, JInt, required = false, default = nil)
  if valid_601635 != nil:
    section.add "MaxRecords", valid_601635
  var valid_601636 = formData.getOrDefault("Source")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "Source", valid_601636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601637: Call_PostDescribeDBClusterParameters_601620;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_601637.validator(path, query, header, formData, body)
  let scheme = call_601637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601637.url(scheme.get, call_601637.host, call_601637.base,
                         call_601637.route, valid.getOrDefault("path"))
  result = hook(call_601637, url, valid)

proc call*(call_601638: Call_PostDescribeDBClusterParameters_601620;
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
  var query_601639 = newJObject()
  var formData_601640 = newJObject()
  add(formData_601640, "Marker", newJString(Marker))
  add(query_601639, "Action", newJString(Action))
  add(formData_601640, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_601640.add "Filters", Filters
  add(formData_601640, "MaxRecords", newJInt(MaxRecords))
  add(query_601639, "Version", newJString(Version))
  add(formData_601640, "Source", newJString(Source))
  result = call_601638.call(nil, query_601639, nil, formData_601640, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_601620(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_601621, base: "/",
    url: url_PostDescribeDBClusterParameters_601622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_601600 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBClusterParameters_601602(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameters_601601(path: JsonNode;
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
  var valid_601603 = query.getOrDefault("MaxRecords")
  valid_601603 = validateParameter(valid_601603, JInt, required = false, default = nil)
  if valid_601603 != nil:
    section.add "MaxRecords", valid_601603
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601604 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "DBClusterParameterGroupName", valid_601604
  var valid_601605 = query.getOrDefault("Filters")
  valid_601605 = validateParameter(valid_601605, JArray, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "Filters", valid_601605
  var valid_601606 = query.getOrDefault("Action")
  valid_601606 = validateParameter(valid_601606, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_601606 != nil:
    section.add "Action", valid_601606
  var valid_601607 = query.getOrDefault("Marker")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "Marker", valid_601607
  var valid_601608 = query.getOrDefault("Source")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "Source", valid_601608
  var valid_601609 = query.getOrDefault("Version")
  valid_601609 = validateParameter(valid_601609, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601609 != nil:
    section.add "Version", valid_601609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601610 = header.getOrDefault("X-Amz-Date")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Date", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Security-Token")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Security-Token", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Content-Sha256", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Algorithm")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Algorithm", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Signature")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Signature", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-SignedHeaders", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Credential")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Credential", valid_601616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601617: Call_GetDescribeDBClusterParameters_601600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_601617.validator(path, query, header, formData, body)
  let scheme = call_601617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601617.url(scheme.get, call_601617.host, call_601617.base,
                         call_601617.route, valid.getOrDefault("path"))
  result = hook(call_601617, url, valid)

proc call*(call_601618: Call_GetDescribeDBClusterParameters_601600;
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
  var query_601619 = newJObject()
  add(query_601619, "MaxRecords", newJInt(MaxRecords))
  add(query_601619, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_601619.add "Filters", Filters
  add(query_601619, "Action", newJString(Action))
  add(query_601619, "Marker", newJString(Marker))
  add(query_601619, "Source", newJString(Source))
  add(query_601619, "Version", newJString(Version))
  result = call_601618.call(nil, query_601619, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_601600(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_601601, base: "/",
    url: url_GetDescribeDBClusterParameters_601602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_601657 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBClusterSnapshotAttributes_601659(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_601658(path: JsonNode;
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
  var valid_601660 = query.getOrDefault("Action")
  valid_601660 = validateParameter(valid_601660, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_601660 != nil:
    section.add "Action", valid_601660
  var valid_601661 = query.getOrDefault("Version")
  valid_601661 = validateParameter(valid_601661, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601661 != nil:
    section.add "Version", valid_601661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601662 = header.getOrDefault("X-Amz-Date")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Date", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Security-Token")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Security-Token", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Content-Sha256", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Algorithm")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Algorithm", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Signature")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Signature", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-SignedHeaders", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Credential")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Credential", valid_601668
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_601669 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601669 = validateParameter(valid_601669, JString, required = true,
                                 default = nil)
  if valid_601669 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601669
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601670: Call_PostDescribeDBClusterSnapshotAttributes_601657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_601670.validator(path, query, header, formData, body)
  let scheme = call_601670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601670.url(scheme.get, call_601670.host, call_601670.base,
                         call_601670.route, valid.getOrDefault("path"))
  result = hook(call_601670, url, valid)

proc call*(call_601671: Call_PostDescribeDBClusterSnapshotAttributes_601657;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601672 = newJObject()
  var formData_601673 = newJObject()
  add(formData_601673, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_601672, "Action", newJString(Action))
  add(query_601672, "Version", newJString(Version))
  result = call_601671.call(nil, query_601672, nil, formData_601673, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_601657(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_601658, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_601659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_601641 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBClusterSnapshotAttributes_601643(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_601642(path: JsonNode;
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
  var valid_601644 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601644 = validateParameter(valid_601644, JString, required = true,
                                 default = nil)
  if valid_601644 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601644
  var valid_601645 = query.getOrDefault("Action")
  valid_601645 = validateParameter(valid_601645, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_601645 != nil:
    section.add "Action", valid_601645
  var valid_601646 = query.getOrDefault("Version")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601646 != nil:
    section.add "Version", valid_601646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601654: Call_GetDescribeDBClusterSnapshotAttributes_601641;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_601654.validator(path, query, header, formData, body)
  let scheme = call_601654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601654.url(scheme.get, call_601654.host, call_601654.base,
                         call_601654.route, valid.getOrDefault("path"))
  result = hook(call_601654, url, valid)

proc call*(call_601655: Call_GetDescribeDBClusterSnapshotAttributes_601641;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601656 = newJObject()
  add(query_601656, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_601656, "Action", newJString(Action))
  add(query_601656, "Version", newJString(Version))
  result = call_601655.call(nil, query_601656, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_601641(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_601642, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_601643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_601697 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBClusterSnapshots_601699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshots_601698(path: JsonNode;
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
  var valid_601700 = query.getOrDefault("Action")
  valid_601700 = validateParameter(valid_601700, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_601700 != nil:
    section.add "Action", valid_601700
  var valid_601701 = query.getOrDefault("Version")
  valid_601701 = validateParameter(valid_601701, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601701 != nil:
    section.add "Version", valid_601701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601702 = header.getOrDefault("X-Amz-Date")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Date", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Security-Token")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Security-Token", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Content-Sha256", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Algorithm")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Algorithm", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Signature")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Signature", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-SignedHeaders", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Credential")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Credential", valid_601708
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
  var valid_601709 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601709
  var valid_601710 = formData.getOrDefault("IncludeShared")
  valid_601710 = validateParameter(valid_601710, JBool, required = false, default = nil)
  if valid_601710 != nil:
    section.add "IncludeShared", valid_601710
  var valid_601711 = formData.getOrDefault("IncludePublic")
  valid_601711 = validateParameter(valid_601711, JBool, required = false, default = nil)
  if valid_601711 != nil:
    section.add "IncludePublic", valid_601711
  var valid_601712 = formData.getOrDefault("SnapshotType")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "SnapshotType", valid_601712
  var valid_601713 = formData.getOrDefault("Marker")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "Marker", valid_601713
  var valid_601714 = formData.getOrDefault("Filters")
  valid_601714 = validateParameter(valid_601714, JArray, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "Filters", valid_601714
  var valid_601715 = formData.getOrDefault("MaxRecords")
  valid_601715 = validateParameter(valid_601715, JInt, required = false, default = nil)
  if valid_601715 != nil:
    section.add "MaxRecords", valid_601715
  var valid_601716 = formData.getOrDefault("DBClusterIdentifier")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "DBClusterIdentifier", valid_601716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601717: Call_PostDescribeDBClusterSnapshots_601697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_601717.validator(path, query, header, formData, body)
  let scheme = call_601717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601717.url(scheme.get, call_601717.host, call_601717.base,
                         call_601717.route, valid.getOrDefault("path"))
  result = hook(call_601717, url, valid)

proc call*(call_601718: Call_PostDescribeDBClusterSnapshots_601697;
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
  var query_601719 = newJObject()
  var formData_601720 = newJObject()
  add(formData_601720, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_601720, "IncludeShared", newJBool(IncludeShared))
  add(formData_601720, "IncludePublic", newJBool(IncludePublic))
  add(formData_601720, "SnapshotType", newJString(SnapshotType))
  add(formData_601720, "Marker", newJString(Marker))
  add(query_601719, "Action", newJString(Action))
  if Filters != nil:
    formData_601720.add "Filters", Filters
  add(formData_601720, "MaxRecords", newJInt(MaxRecords))
  add(formData_601720, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601719, "Version", newJString(Version))
  result = call_601718.call(nil, query_601719, nil, formData_601720, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_601697(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_601698, base: "/",
    url: url_PostDescribeDBClusterSnapshots_601699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_601674 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBClusterSnapshots_601676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshots_601675(path: JsonNode; query: JsonNode;
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
  var valid_601677 = query.getOrDefault("IncludePublic")
  valid_601677 = validateParameter(valid_601677, JBool, required = false, default = nil)
  if valid_601677 != nil:
    section.add "IncludePublic", valid_601677
  var valid_601678 = query.getOrDefault("MaxRecords")
  valid_601678 = validateParameter(valid_601678, JInt, required = false, default = nil)
  if valid_601678 != nil:
    section.add "MaxRecords", valid_601678
  var valid_601679 = query.getOrDefault("DBClusterIdentifier")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "DBClusterIdentifier", valid_601679
  var valid_601680 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601680
  var valid_601681 = query.getOrDefault("Filters")
  valid_601681 = validateParameter(valid_601681, JArray, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "Filters", valid_601681
  var valid_601682 = query.getOrDefault("IncludeShared")
  valid_601682 = validateParameter(valid_601682, JBool, required = false, default = nil)
  if valid_601682 != nil:
    section.add "IncludeShared", valid_601682
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601683 = query.getOrDefault("Action")
  valid_601683 = validateParameter(valid_601683, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_601683 != nil:
    section.add "Action", valid_601683
  var valid_601684 = query.getOrDefault("Marker")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "Marker", valid_601684
  var valid_601685 = query.getOrDefault("SnapshotType")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "SnapshotType", valid_601685
  var valid_601686 = query.getOrDefault("Version")
  valid_601686 = validateParameter(valid_601686, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601686 != nil:
    section.add "Version", valid_601686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601687 = header.getOrDefault("X-Amz-Date")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Date", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Security-Token")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Security-Token", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Content-Sha256", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Algorithm")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Algorithm", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Signature")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Signature", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-SignedHeaders", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Credential")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Credential", valid_601693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601694: Call_GetDescribeDBClusterSnapshots_601674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_601694.validator(path, query, header, formData, body)
  let scheme = call_601694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601694.url(scheme.get, call_601694.host, call_601694.base,
                         call_601694.route, valid.getOrDefault("path"))
  result = hook(call_601694, url, valid)

proc call*(call_601695: Call_GetDescribeDBClusterSnapshots_601674;
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
  var query_601696 = newJObject()
  add(query_601696, "IncludePublic", newJBool(IncludePublic))
  add(query_601696, "MaxRecords", newJInt(MaxRecords))
  add(query_601696, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601696, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_601696.add "Filters", Filters
  add(query_601696, "IncludeShared", newJBool(IncludeShared))
  add(query_601696, "Action", newJString(Action))
  add(query_601696, "Marker", newJString(Marker))
  add(query_601696, "SnapshotType", newJString(SnapshotType))
  add(query_601696, "Version", newJString(Version))
  result = call_601695.call(nil, query_601696, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_601674(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_601675, base: "/",
    url: url_GetDescribeDBClusterSnapshots_601676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_601740 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBClusters_601742(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusters_601741(path: JsonNode; query: JsonNode;
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
  var valid_601743 = query.getOrDefault("Action")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_601743 != nil:
    section.add "Action", valid_601743
  var valid_601744 = query.getOrDefault("Version")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601744 != nil:
    section.add "Version", valid_601744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601745 = header.getOrDefault("X-Amz-Date")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Date", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Security-Token")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Security-Token", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Content-Sha256", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Algorithm")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Algorithm", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Signature")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Signature", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-SignedHeaders", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Credential")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Credential", valid_601751
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
  var valid_601752 = formData.getOrDefault("Marker")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "Marker", valid_601752
  var valid_601753 = formData.getOrDefault("Filters")
  valid_601753 = validateParameter(valid_601753, JArray, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "Filters", valid_601753
  var valid_601754 = formData.getOrDefault("MaxRecords")
  valid_601754 = validateParameter(valid_601754, JInt, required = false, default = nil)
  if valid_601754 != nil:
    section.add "MaxRecords", valid_601754
  var valid_601755 = formData.getOrDefault("DBClusterIdentifier")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "DBClusterIdentifier", valid_601755
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601756: Call_PostDescribeDBClusters_601740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_601756.validator(path, query, header, formData, body)
  let scheme = call_601756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601756.url(scheme.get, call_601756.host, call_601756.base,
                         call_601756.route, valid.getOrDefault("path"))
  result = hook(call_601756, url, valid)

proc call*(call_601757: Call_PostDescribeDBClusters_601740; Marker: string = "";
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
  var query_601758 = newJObject()
  var formData_601759 = newJObject()
  add(formData_601759, "Marker", newJString(Marker))
  add(query_601758, "Action", newJString(Action))
  if Filters != nil:
    formData_601759.add "Filters", Filters
  add(formData_601759, "MaxRecords", newJInt(MaxRecords))
  add(formData_601759, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601758, "Version", newJString(Version))
  result = call_601757.call(nil, query_601758, nil, formData_601759, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_601740(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_601741, base: "/",
    url: url_PostDescribeDBClusters_601742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_601721 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBClusters_601723(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusters_601722(path: JsonNode; query: JsonNode;
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
  var valid_601724 = query.getOrDefault("MaxRecords")
  valid_601724 = validateParameter(valid_601724, JInt, required = false, default = nil)
  if valid_601724 != nil:
    section.add "MaxRecords", valid_601724
  var valid_601725 = query.getOrDefault("DBClusterIdentifier")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "DBClusterIdentifier", valid_601725
  var valid_601726 = query.getOrDefault("Filters")
  valid_601726 = validateParameter(valid_601726, JArray, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "Filters", valid_601726
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601727 = query.getOrDefault("Action")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_601727 != nil:
    section.add "Action", valid_601727
  var valid_601728 = query.getOrDefault("Marker")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "Marker", valid_601728
  var valid_601729 = query.getOrDefault("Version")
  valid_601729 = validateParameter(valid_601729, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601729 != nil:
    section.add "Version", valid_601729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601730 = header.getOrDefault("X-Amz-Date")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Date", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Security-Token")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Security-Token", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Content-Sha256", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Algorithm")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Algorithm", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Signature")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Signature", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-SignedHeaders", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Credential")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Credential", valid_601736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601737: Call_GetDescribeDBClusters_601721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_601737.validator(path, query, header, formData, body)
  let scheme = call_601737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601737.url(scheme.get, call_601737.host, call_601737.base,
                         call_601737.route, valid.getOrDefault("path"))
  result = hook(call_601737, url, valid)

proc call*(call_601738: Call_GetDescribeDBClusters_601721; MaxRecords: int = 0;
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
  var query_601739 = newJObject()
  add(query_601739, "MaxRecords", newJInt(MaxRecords))
  add(query_601739, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_601739.add "Filters", Filters
  add(query_601739, "Action", newJString(Action))
  add(query_601739, "Marker", newJString(Marker))
  add(query_601739, "Version", newJString(Version))
  result = call_601738.call(nil, query_601739, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_601721(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_601722, base: "/",
    url: url_GetDescribeDBClusters_601723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601784 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBEngineVersions_601786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_601785(path: JsonNode; query: JsonNode;
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
  var valid_601787 = query.getOrDefault("Action")
  valid_601787 = validateParameter(valid_601787, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601787 != nil:
    section.add "Action", valid_601787
  var valid_601788 = query.getOrDefault("Version")
  valid_601788 = validateParameter(valid_601788, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601788 != nil:
    section.add "Version", valid_601788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601789 = header.getOrDefault("X-Amz-Date")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Date", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-Security-Token")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Security-Token", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Content-Sha256", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Algorithm")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Algorithm", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Signature")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Signature", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-SignedHeaders", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Credential")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Credential", valid_601795
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
  var valid_601796 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601796 = validateParameter(valid_601796, JBool, required = false, default = nil)
  if valid_601796 != nil:
    section.add "ListSupportedCharacterSets", valid_601796
  var valid_601797 = formData.getOrDefault("Engine")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "Engine", valid_601797
  var valid_601798 = formData.getOrDefault("Marker")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "Marker", valid_601798
  var valid_601799 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "DBParameterGroupFamily", valid_601799
  var valid_601800 = formData.getOrDefault("Filters")
  valid_601800 = validateParameter(valid_601800, JArray, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "Filters", valid_601800
  var valid_601801 = formData.getOrDefault("MaxRecords")
  valid_601801 = validateParameter(valid_601801, JInt, required = false, default = nil)
  if valid_601801 != nil:
    section.add "MaxRecords", valid_601801
  var valid_601802 = formData.getOrDefault("EngineVersion")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "EngineVersion", valid_601802
  var valid_601803 = formData.getOrDefault("ListSupportedTimezones")
  valid_601803 = validateParameter(valid_601803, JBool, required = false, default = nil)
  if valid_601803 != nil:
    section.add "ListSupportedTimezones", valid_601803
  var valid_601804 = formData.getOrDefault("DefaultOnly")
  valid_601804 = validateParameter(valid_601804, JBool, required = false, default = nil)
  if valid_601804 != nil:
    section.add "DefaultOnly", valid_601804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601805: Call_PostDescribeDBEngineVersions_601784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_601805.validator(path, query, header, formData, body)
  let scheme = call_601805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601805.url(scheme.get, call_601805.host, call_601805.base,
                         call_601805.route, valid.getOrDefault("path"))
  result = hook(call_601805, url, valid)

proc call*(call_601806: Call_PostDescribeDBEngineVersions_601784;
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
  var query_601807 = newJObject()
  var formData_601808 = newJObject()
  add(formData_601808, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601808, "Engine", newJString(Engine))
  add(formData_601808, "Marker", newJString(Marker))
  add(query_601807, "Action", newJString(Action))
  add(formData_601808, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601808.add "Filters", Filters
  add(formData_601808, "MaxRecords", newJInt(MaxRecords))
  add(formData_601808, "EngineVersion", newJString(EngineVersion))
  add(formData_601808, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_601807, "Version", newJString(Version))
  add(formData_601808, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601806.call(nil, query_601807, nil, formData_601808, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601784(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601785, base: "/",
    url: url_PostDescribeDBEngineVersions_601786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601760 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBEngineVersions_601762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_601761(path: JsonNode; query: JsonNode;
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
  var valid_601763 = query.getOrDefault("Engine")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "Engine", valid_601763
  var valid_601764 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601764 = validateParameter(valid_601764, JBool, required = false, default = nil)
  if valid_601764 != nil:
    section.add "ListSupportedCharacterSets", valid_601764
  var valid_601765 = query.getOrDefault("MaxRecords")
  valid_601765 = validateParameter(valid_601765, JInt, required = false, default = nil)
  if valid_601765 != nil:
    section.add "MaxRecords", valid_601765
  var valid_601766 = query.getOrDefault("DBParameterGroupFamily")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "DBParameterGroupFamily", valid_601766
  var valid_601767 = query.getOrDefault("Filters")
  valid_601767 = validateParameter(valid_601767, JArray, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "Filters", valid_601767
  var valid_601768 = query.getOrDefault("ListSupportedTimezones")
  valid_601768 = validateParameter(valid_601768, JBool, required = false, default = nil)
  if valid_601768 != nil:
    section.add "ListSupportedTimezones", valid_601768
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601769 = query.getOrDefault("Action")
  valid_601769 = validateParameter(valid_601769, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601769 != nil:
    section.add "Action", valid_601769
  var valid_601770 = query.getOrDefault("Marker")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "Marker", valid_601770
  var valid_601771 = query.getOrDefault("EngineVersion")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "EngineVersion", valid_601771
  var valid_601772 = query.getOrDefault("DefaultOnly")
  valid_601772 = validateParameter(valid_601772, JBool, required = false, default = nil)
  if valid_601772 != nil:
    section.add "DefaultOnly", valid_601772
  var valid_601773 = query.getOrDefault("Version")
  valid_601773 = validateParameter(valid_601773, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601773 != nil:
    section.add "Version", valid_601773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601774 = header.getOrDefault("X-Amz-Date")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Date", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Security-Token")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Security-Token", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Content-Sha256", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Algorithm")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Algorithm", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Signature")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Signature", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-SignedHeaders", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Credential")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Credential", valid_601780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601781: Call_GetDescribeDBEngineVersions_601760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_601781.validator(path, query, header, formData, body)
  let scheme = call_601781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601781.url(scheme.get, call_601781.host, call_601781.base,
                         call_601781.route, valid.getOrDefault("path"))
  result = hook(call_601781, url, valid)

proc call*(call_601782: Call_GetDescribeDBEngineVersions_601760;
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
  var query_601783 = newJObject()
  add(query_601783, "Engine", newJString(Engine))
  add(query_601783, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601783, "MaxRecords", newJInt(MaxRecords))
  add(query_601783, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601783.add "Filters", Filters
  add(query_601783, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_601783, "Action", newJString(Action))
  add(query_601783, "Marker", newJString(Marker))
  add(query_601783, "EngineVersion", newJString(EngineVersion))
  add(query_601783, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601783, "Version", newJString(Version))
  result = call_601782.call(nil, query_601783, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601760(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601761, base: "/",
    url: url_GetDescribeDBEngineVersions_601762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601828 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBInstances_601830(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_601829(path: JsonNode; query: JsonNode;
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
  var valid_601831 = query.getOrDefault("Action")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601831 != nil:
    section.add "Action", valid_601831
  var valid_601832 = query.getOrDefault("Version")
  valid_601832 = validateParameter(valid_601832, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601832 != nil:
    section.add "Version", valid_601832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601833 = header.getOrDefault("X-Amz-Date")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Date", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Security-Token")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Security-Token", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Content-Sha256", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Algorithm")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Algorithm", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Signature")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Signature", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-SignedHeaders", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Credential")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Credential", valid_601839
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
  var valid_601840 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "DBInstanceIdentifier", valid_601840
  var valid_601841 = formData.getOrDefault("Marker")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "Marker", valid_601841
  var valid_601842 = formData.getOrDefault("Filters")
  valid_601842 = validateParameter(valid_601842, JArray, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "Filters", valid_601842
  var valid_601843 = formData.getOrDefault("MaxRecords")
  valid_601843 = validateParameter(valid_601843, JInt, required = false, default = nil)
  if valid_601843 != nil:
    section.add "MaxRecords", valid_601843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601844: Call_PostDescribeDBInstances_601828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_601844.validator(path, query, header, formData, body)
  let scheme = call_601844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601844.url(scheme.get, call_601844.host, call_601844.base,
                         call_601844.route, valid.getOrDefault("path"))
  result = hook(call_601844, url, valid)

proc call*(call_601845: Call_PostDescribeDBInstances_601828;
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
  var query_601846 = newJObject()
  var formData_601847 = newJObject()
  add(formData_601847, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601847, "Marker", newJString(Marker))
  add(query_601846, "Action", newJString(Action))
  if Filters != nil:
    formData_601847.add "Filters", Filters
  add(formData_601847, "MaxRecords", newJInt(MaxRecords))
  add(query_601846, "Version", newJString(Version))
  result = call_601845.call(nil, query_601846, nil, formData_601847, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601828(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601829, base: "/",
    url: url_PostDescribeDBInstances_601830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601809 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBInstances_601811(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_601810(path: JsonNode; query: JsonNode;
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
  var valid_601812 = query.getOrDefault("MaxRecords")
  valid_601812 = validateParameter(valid_601812, JInt, required = false, default = nil)
  if valid_601812 != nil:
    section.add "MaxRecords", valid_601812
  var valid_601813 = query.getOrDefault("Filters")
  valid_601813 = validateParameter(valid_601813, JArray, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "Filters", valid_601813
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601814 = query.getOrDefault("Action")
  valid_601814 = validateParameter(valid_601814, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601814 != nil:
    section.add "Action", valid_601814
  var valid_601815 = query.getOrDefault("Marker")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "Marker", valid_601815
  var valid_601816 = query.getOrDefault("Version")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601816 != nil:
    section.add "Version", valid_601816
  var valid_601817 = query.getOrDefault("DBInstanceIdentifier")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "DBInstanceIdentifier", valid_601817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601818 = header.getOrDefault("X-Amz-Date")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Date", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Security-Token")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Security-Token", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Content-Sha256", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Algorithm")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Algorithm", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Signature")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Signature", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-SignedHeaders", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Credential")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Credential", valid_601824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601825: Call_GetDescribeDBInstances_601809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_601825.validator(path, query, header, formData, body)
  let scheme = call_601825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601825.url(scheme.get, call_601825.host, call_601825.base,
                         call_601825.route, valid.getOrDefault("path"))
  result = hook(call_601825, url, valid)

proc call*(call_601826: Call_GetDescribeDBInstances_601809; MaxRecords: int = 0;
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
  var query_601827 = newJObject()
  add(query_601827, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601827.add "Filters", Filters
  add(query_601827, "Action", newJString(Action))
  add(query_601827, "Marker", newJString(Marker))
  add(query_601827, "Version", newJString(Version))
  add(query_601827, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601826.call(nil, query_601827, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601809(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601810, base: "/",
    url: url_GetDescribeDBInstances_601811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_601867 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSubnetGroups_601869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_601868(path: JsonNode; query: JsonNode;
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
  var valid_601870 = query.getOrDefault("Action")
  valid_601870 = validateParameter(valid_601870, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601870 != nil:
    section.add "Action", valid_601870
  var valid_601871 = query.getOrDefault("Version")
  valid_601871 = validateParameter(valid_601871, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601871 != nil:
    section.add "Version", valid_601871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601872 = header.getOrDefault("X-Amz-Date")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Date", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Security-Token")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Security-Token", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Content-Sha256", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Algorithm")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Algorithm", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Signature")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Signature", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-SignedHeaders", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Credential")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Credential", valid_601878
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
  var valid_601879 = formData.getOrDefault("DBSubnetGroupName")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "DBSubnetGroupName", valid_601879
  var valid_601880 = formData.getOrDefault("Marker")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "Marker", valid_601880
  var valid_601881 = formData.getOrDefault("Filters")
  valid_601881 = validateParameter(valid_601881, JArray, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "Filters", valid_601881
  var valid_601882 = formData.getOrDefault("MaxRecords")
  valid_601882 = validateParameter(valid_601882, JInt, required = false, default = nil)
  if valid_601882 != nil:
    section.add "MaxRecords", valid_601882
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601883: Call_PostDescribeDBSubnetGroups_601867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_601883.validator(path, query, header, formData, body)
  let scheme = call_601883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601883.url(scheme.get, call_601883.host, call_601883.base,
                         call_601883.route, valid.getOrDefault("path"))
  result = hook(call_601883, url, valid)

proc call*(call_601884: Call_PostDescribeDBSubnetGroups_601867;
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
  var query_601885 = newJObject()
  var formData_601886 = newJObject()
  add(formData_601886, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601886, "Marker", newJString(Marker))
  add(query_601885, "Action", newJString(Action))
  if Filters != nil:
    formData_601886.add "Filters", Filters
  add(formData_601886, "MaxRecords", newJInt(MaxRecords))
  add(query_601885, "Version", newJString(Version))
  result = call_601884.call(nil, query_601885, nil, formData_601886, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_601867(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_601868, base: "/",
    url: url_PostDescribeDBSubnetGroups_601869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_601848 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSubnetGroups_601850(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_601849(path: JsonNode; query: JsonNode;
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
  var valid_601851 = query.getOrDefault("MaxRecords")
  valid_601851 = validateParameter(valid_601851, JInt, required = false, default = nil)
  if valid_601851 != nil:
    section.add "MaxRecords", valid_601851
  var valid_601852 = query.getOrDefault("Filters")
  valid_601852 = validateParameter(valid_601852, JArray, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "Filters", valid_601852
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601853 = query.getOrDefault("Action")
  valid_601853 = validateParameter(valid_601853, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601853 != nil:
    section.add "Action", valid_601853
  var valid_601854 = query.getOrDefault("Marker")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "Marker", valid_601854
  var valid_601855 = query.getOrDefault("DBSubnetGroupName")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "DBSubnetGroupName", valid_601855
  var valid_601856 = query.getOrDefault("Version")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601856 != nil:
    section.add "Version", valid_601856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Security-Token")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Security-Token", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Signature")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Signature", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Credential")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Credential", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601864: Call_GetDescribeDBSubnetGroups_601848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_601864.validator(path, query, header, formData, body)
  let scheme = call_601864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601864.url(scheme.get, call_601864.host, call_601864.base,
                         call_601864.route, valid.getOrDefault("path"))
  result = hook(call_601864, url, valid)

proc call*(call_601865: Call_GetDescribeDBSubnetGroups_601848; MaxRecords: int = 0;
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
  var query_601866 = newJObject()
  add(query_601866, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601866.add "Filters", Filters
  add(query_601866, "Action", newJString(Action))
  add(query_601866, "Marker", newJString(Marker))
  add(query_601866, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601866, "Version", newJString(Version))
  result = call_601865.call(nil, query_601866, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_601848(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_601849, base: "/",
    url: url_GetDescribeDBSubnetGroups_601850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_601906 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEngineDefaultClusterParameters_601908(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultClusterParameters_601907(path: JsonNode;
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
  var valid_601909 = query.getOrDefault("Action")
  valid_601909 = validateParameter(valid_601909, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_601909 != nil:
    section.add "Action", valid_601909
  var valid_601910 = query.getOrDefault("Version")
  valid_601910 = validateParameter(valid_601910, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601910 != nil:
    section.add "Version", valid_601910
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601911 = header.getOrDefault("X-Amz-Date")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Date", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Security-Token")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Security-Token", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Content-Sha256", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Algorithm")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Algorithm", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Signature")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Signature", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-SignedHeaders", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Credential")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Credential", valid_601917
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
  var valid_601918 = formData.getOrDefault("Marker")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "Marker", valid_601918
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601919 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601919 = validateParameter(valid_601919, JString, required = true,
                                 default = nil)
  if valid_601919 != nil:
    section.add "DBParameterGroupFamily", valid_601919
  var valid_601920 = formData.getOrDefault("Filters")
  valid_601920 = validateParameter(valid_601920, JArray, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "Filters", valid_601920
  var valid_601921 = formData.getOrDefault("MaxRecords")
  valid_601921 = validateParameter(valid_601921, JInt, required = false, default = nil)
  if valid_601921 != nil:
    section.add "MaxRecords", valid_601921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601922: Call_PostDescribeEngineDefaultClusterParameters_601906;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_601922.validator(path, query, header, formData, body)
  let scheme = call_601922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601922.url(scheme.get, call_601922.host, call_601922.base,
                         call_601922.route, valid.getOrDefault("path"))
  result = hook(call_601922, url, valid)

proc call*(call_601923: Call_PostDescribeEngineDefaultClusterParameters_601906;
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
  var query_601924 = newJObject()
  var formData_601925 = newJObject()
  add(formData_601925, "Marker", newJString(Marker))
  add(query_601924, "Action", newJString(Action))
  add(formData_601925, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601925.add "Filters", Filters
  add(formData_601925, "MaxRecords", newJInt(MaxRecords))
  add(query_601924, "Version", newJString(Version))
  result = call_601923.call(nil, query_601924, nil, formData_601925, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_601906(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_601907,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_601908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_601887 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEngineDefaultClusterParameters_601889(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultClusterParameters_601888(path: JsonNode;
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
  var valid_601890 = query.getOrDefault("MaxRecords")
  valid_601890 = validateParameter(valid_601890, JInt, required = false, default = nil)
  if valid_601890 != nil:
    section.add "MaxRecords", valid_601890
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601891 = query.getOrDefault("DBParameterGroupFamily")
  valid_601891 = validateParameter(valid_601891, JString, required = true,
                                 default = nil)
  if valid_601891 != nil:
    section.add "DBParameterGroupFamily", valid_601891
  var valid_601892 = query.getOrDefault("Filters")
  valid_601892 = validateParameter(valid_601892, JArray, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "Filters", valid_601892
  var valid_601893 = query.getOrDefault("Action")
  valid_601893 = validateParameter(valid_601893, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_601893 != nil:
    section.add "Action", valid_601893
  var valid_601894 = query.getOrDefault("Marker")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "Marker", valid_601894
  var valid_601895 = query.getOrDefault("Version")
  valid_601895 = validateParameter(valid_601895, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601903: Call_GetDescribeEngineDefaultClusterParameters_601887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_601903.validator(path, query, header, formData, body)
  let scheme = call_601903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601903.url(scheme.get, call_601903.host, call_601903.base,
                         call_601903.route, valid.getOrDefault("path"))
  result = hook(call_601903, url, valid)

proc call*(call_601904: Call_GetDescribeEngineDefaultClusterParameters_601887;
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
  var query_601905 = newJObject()
  add(query_601905, "MaxRecords", newJInt(MaxRecords))
  add(query_601905, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601905.add "Filters", Filters
  add(query_601905, "Action", newJString(Action))
  add(query_601905, "Marker", newJString(Marker))
  add(query_601905, "Version", newJString(Version))
  result = call_601904.call(nil, query_601905, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_601887(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_601888,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_601889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_601943 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventCategories_601945(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_601944(path: JsonNode; query: JsonNode;
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
  var valid_601946 = query.getOrDefault("Action")
  valid_601946 = validateParameter(valid_601946, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601946 != nil:
    section.add "Action", valid_601946
  var valid_601947 = query.getOrDefault("Version")
  valid_601947 = validateParameter(valid_601947, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601947 != nil:
    section.add "Version", valid_601947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601948 = header.getOrDefault("X-Amz-Date")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Date", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Security-Token")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Security-Token", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Content-Sha256", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Algorithm")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Algorithm", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Signature")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Signature", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-SignedHeaders", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Credential")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Credential", valid_601954
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_601955 = formData.getOrDefault("Filters")
  valid_601955 = validateParameter(valid_601955, JArray, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "Filters", valid_601955
  var valid_601956 = formData.getOrDefault("SourceType")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "SourceType", valid_601956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601957: Call_PostDescribeEventCategories_601943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_601957.validator(path, query, header, formData, body)
  let scheme = call_601957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601957.url(scheme.get, call_601957.host, call_601957.base,
                         call_601957.route, valid.getOrDefault("path"))
  result = hook(call_601957, url, valid)

proc call*(call_601958: Call_PostDescribeEventCategories_601943;
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
  var query_601959 = newJObject()
  var formData_601960 = newJObject()
  add(query_601959, "Action", newJString(Action))
  if Filters != nil:
    formData_601960.add "Filters", Filters
  add(query_601959, "Version", newJString(Version))
  add(formData_601960, "SourceType", newJString(SourceType))
  result = call_601958.call(nil, query_601959, nil, formData_601960, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_601943(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_601944, base: "/",
    url: url_PostDescribeEventCategories_601945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_601926 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventCategories_601928(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_601927(path: JsonNode; query: JsonNode;
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
  var valid_601929 = query.getOrDefault("SourceType")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "SourceType", valid_601929
  var valid_601930 = query.getOrDefault("Filters")
  valid_601930 = validateParameter(valid_601930, JArray, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "Filters", valid_601930
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601931 = query.getOrDefault("Action")
  valid_601931 = validateParameter(valid_601931, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601931 != nil:
    section.add "Action", valid_601931
  var valid_601932 = query.getOrDefault("Version")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601932 != nil:
    section.add "Version", valid_601932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601933 = header.getOrDefault("X-Amz-Date")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Date", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Security-Token")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Security-Token", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Content-Sha256", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Algorithm")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Algorithm", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Signature")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Signature", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-SignedHeaders", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-Credential")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-Credential", valid_601939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601940: Call_GetDescribeEventCategories_601926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_601940.validator(path, query, header, formData, body)
  let scheme = call_601940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601940.url(scheme.get, call_601940.host, call_601940.base,
                         call_601940.route, valid.getOrDefault("path"))
  result = hook(call_601940, url, valid)

proc call*(call_601941: Call_GetDescribeEventCategories_601926;
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
  var query_601942 = newJObject()
  add(query_601942, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_601942.add "Filters", Filters
  add(query_601942, "Action", newJString(Action))
  add(query_601942, "Version", newJString(Version))
  result = call_601941.call(nil, query_601942, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_601926(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_601927, base: "/",
    url: url_GetDescribeEventCategories_601928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_601985 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEvents_601987(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_601986(path: JsonNode; query: JsonNode;
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
  var valid_601988 = query.getOrDefault("Action")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601988 != nil:
    section.add "Action", valid_601988
  var valid_601989 = query.getOrDefault("Version")
  valid_601989 = validateParameter(valid_601989, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601989 != nil:
    section.add "Version", valid_601989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Algorithm")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Algorithm", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Signature")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Signature", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Credential")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Credential", valid_601996
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
  var valid_601997 = formData.getOrDefault("SourceIdentifier")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "SourceIdentifier", valid_601997
  var valid_601998 = formData.getOrDefault("EventCategories")
  valid_601998 = validateParameter(valid_601998, JArray, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "EventCategories", valid_601998
  var valid_601999 = formData.getOrDefault("Marker")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "Marker", valid_601999
  var valid_602000 = formData.getOrDefault("StartTime")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "StartTime", valid_602000
  var valid_602001 = formData.getOrDefault("Duration")
  valid_602001 = validateParameter(valid_602001, JInt, required = false, default = nil)
  if valid_602001 != nil:
    section.add "Duration", valid_602001
  var valid_602002 = formData.getOrDefault("Filters")
  valid_602002 = validateParameter(valid_602002, JArray, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "Filters", valid_602002
  var valid_602003 = formData.getOrDefault("EndTime")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "EndTime", valid_602003
  var valid_602004 = formData.getOrDefault("MaxRecords")
  valid_602004 = validateParameter(valid_602004, JInt, required = false, default = nil)
  if valid_602004 != nil:
    section.add "MaxRecords", valid_602004
  var valid_602005 = formData.getOrDefault("SourceType")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602005 != nil:
    section.add "SourceType", valid_602005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602006: Call_PostDescribeEvents_601985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_602006.validator(path, query, header, formData, body)
  let scheme = call_602006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602006.url(scheme.get, call_602006.host, call_602006.base,
                         call_602006.route, valid.getOrDefault("path"))
  result = hook(call_602006, url, valid)

proc call*(call_602007: Call_PostDescribeEvents_601985;
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
  var query_602008 = newJObject()
  var formData_602009 = newJObject()
  add(formData_602009, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602009.add "EventCategories", EventCategories
  add(formData_602009, "Marker", newJString(Marker))
  add(formData_602009, "StartTime", newJString(StartTime))
  add(query_602008, "Action", newJString(Action))
  add(formData_602009, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_602009.add "Filters", Filters
  add(formData_602009, "EndTime", newJString(EndTime))
  add(formData_602009, "MaxRecords", newJInt(MaxRecords))
  add(query_602008, "Version", newJString(Version))
  add(formData_602009, "SourceType", newJString(SourceType))
  result = call_602007.call(nil, query_602008, nil, formData_602009, nil)

var postDescribeEvents* = Call_PostDescribeEvents_601985(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_601986, base: "/",
    url: url_PostDescribeEvents_601987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_601961 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEvents_601963(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_601962(path: JsonNode; query: JsonNode;
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
  var valid_601964 = query.getOrDefault("SourceType")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601964 != nil:
    section.add "SourceType", valid_601964
  var valid_601965 = query.getOrDefault("MaxRecords")
  valid_601965 = validateParameter(valid_601965, JInt, required = false, default = nil)
  if valid_601965 != nil:
    section.add "MaxRecords", valid_601965
  var valid_601966 = query.getOrDefault("StartTime")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "StartTime", valid_601966
  var valid_601967 = query.getOrDefault("Filters")
  valid_601967 = validateParameter(valid_601967, JArray, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "Filters", valid_601967
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601968 = query.getOrDefault("Action")
  valid_601968 = validateParameter(valid_601968, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601968 != nil:
    section.add "Action", valid_601968
  var valid_601969 = query.getOrDefault("SourceIdentifier")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "SourceIdentifier", valid_601969
  var valid_601970 = query.getOrDefault("Marker")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "Marker", valid_601970
  var valid_601971 = query.getOrDefault("EventCategories")
  valid_601971 = validateParameter(valid_601971, JArray, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "EventCategories", valid_601971
  var valid_601972 = query.getOrDefault("Duration")
  valid_601972 = validateParameter(valid_601972, JInt, required = false, default = nil)
  if valid_601972 != nil:
    section.add "Duration", valid_601972
  var valid_601973 = query.getOrDefault("EndTime")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "EndTime", valid_601973
  var valid_601974 = query.getOrDefault("Version")
  valid_601974 = validateParameter(valid_601974, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601974 != nil:
    section.add "Version", valid_601974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601975 = header.getOrDefault("X-Amz-Date")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Date", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Security-Token")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Security-Token", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Content-Sha256", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Algorithm")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Algorithm", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Signature")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Signature", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-SignedHeaders", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Credential")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Credential", valid_601981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601982: Call_GetDescribeEvents_601961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_601982.validator(path, query, header, formData, body)
  let scheme = call_601982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601982.url(scheme.get, call_601982.host, call_601982.base,
                         call_601982.route, valid.getOrDefault("path"))
  result = hook(call_601982, url, valid)

proc call*(call_601983: Call_GetDescribeEvents_601961;
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
  var query_601984 = newJObject()
  add(query_601984, "SourceType", newJString(SourceType))
  add(query_601984, "MaxRecords", newJInt(MaxRecords))
  add(query_601984, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_601984.add "Filters", Filters
  add(query_601984, "Action", newJString(Action))
  add(query_601984, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601984, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_601984.add "EventCategories", EventCategories
  add(query_601984, "Duration", newJInt(Duration))
  add(query_601984, "EndTime", newJString(EndTime))
  add(query_601984, "Version", newJString(Version))
  result = call_601983.call(nil, query_601984, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_601961(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_601962,
    base: "/", url: url_GetDescribeEvents_601963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602033 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOrderableDBInstanceOptions_602035(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602034(path: JsonNode;
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
  var valid_602036 = query.getOrDefault("Action")
  valid_602036 = validateParameter(valid_602036, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602036 != nil:
    section.add "Action", valid_602036
  var valid_602037 = query.getOrDefault("Version")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602037 != nil:
    section.add "Version", valid_602037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Security-Token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Security-Token", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-SignedHeaders", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
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
  var valid_602045 = formData.getOrDefault("Engine")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "Engine", valid_602045
  var valid_602046 = formData.getOrDefault("Marker")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "Marker", valid_602046
  var valid_602047 = formData.getOrDefault("Vpc")
  valid_602047 = validateParameter(valid_602047, JBool, required = false, default = nil)
  if valid_602047 != nil:
    section.add "Vpc", valid_602047
  var valid_602048 = formData.getOrDefault("DBInstanceClass")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "DBInstanceClass", valid_602048
  var valid_602049 = formData.getOrDefault("Filters")
  valid_602049 = validateParameter(valid_602049, JArray, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "Filters", valid_602049
  var valid_602050 = formData.getOrDefault("LicenseModel")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "LicenseModel", valid_602050
  var valid_602051 = formData.getOrDefault("MaxRecords")
  valid_602051 = validateParameter(valid_602051, JInt, required = false, default = nil)
  if valid_602051 != nil:
    section.add "MaxRecords", valid_602051
  var valid_602052 = formData.getOrDefault("EngineVersion")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "EngineVersion", valid_602052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_PostDescribeOrderableDBInstanceOptions_602033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"))
  result = hook(call_602053, url, valid)

proc call*(call_602054: Call_PostDescribeOrderableDBInstanceOptions_602033;
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
  var query_602055 = newJObject()
  var formData_602056 = newJObject()
  add(formData_602056, "Engine", newJString(Engine))
  add(formData_602056, "Marker", newJString(Marker))
  add(query_602055, "Action", newJString(Action))
  add(formData_602056, "Vpc", newJBool(Vpc))
  add(formData_602056, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602056.add "Filters", Filters
  add(formData_602056, "LicenseModel", newJString(LicenseModel))
  add(formData_602056, "MaxRecords", newJInt(MaxRecords))
  add(formData_602056, "EngineVersion", newJString(EngineVersion))
  add(query_602055, "Version", newJString(Version))
  result = call_602054.call(nil, query_602055, nil, formData_602056, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602033(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602034, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602010 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOrderableDBInstanceOptions_602012(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602011(path: JsonNode;
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
  var valid_602013 = query.getOrDefault("Engine")
  valid_602013 = validateParameter(valid_602013, JString, required = true,
                                 default = nil)
  if valid_602013 != nil:
    section.add "Engine", valid_602013
  var valid_602014 = query.getOrDefault("MaxRecords")
  valid_602014 = validateParameter(valid_602014, JInt, required = false, default = nil)
  if valid_602014 != nil:
    section.add "MaxRecords", valid_602014
  var valid_602015 = query.getOrDefault("Filters")
  valid_602015 = validateParameter(valid_602015, JArray, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "Filters", valid_602015
  var valid_602016 = query.getOrDefault("LicenseModel")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "LicenseModel", valid_602016
  var valid_602017 = query.getOrDefault("Vpc")
  valid_602017 = validateParameter(valid_602017, JBool, required = false, default = nil)
  if valid_602017 != nil:
    section.add "Vpc", valid_602017
  var valid_602018 = query.getOrDefault("DBInstanceClass")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "DBInstanceClass", valid_602018
  var valid_602019 = query.getOrDefault("Action")
  valid_602019 = validateParameter(valid_602019, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602019 != nil:
    section.add "Action", valid_602019
  var valid_602020 = query.getOrDefault("Marker")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "Marker", valid_602020
  var valid_602021 = query.getOrDefault("EngineVersion")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "EngineVersion", valid_602021
  var valid_602022 = query.getOrDefault("Version")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602022 != nil:
    section.add "Version", valid_602022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Credential")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Credential", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602030: Call_GetDescribeOrderableDBInstanceOptions_602010;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"))
  result = hook(call_602030, url, valid)

proc call*(call_602031: Call_GetDescribeOrderableDBInstanceOptions_602010;
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
  var query_602032 = newJObject()
  add(query_602032, "Engine", newJString(Engine))
  add(query_602032, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602032.add "Filters", Filters
  add(query_602032, "LicenseModel", newJString(LicenseModel))
  add(query_602032, "Vpc", newJBool(Vpc))
  add(query_602032, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602032, "Action", newJString(Action))
  add(query_602032, "Marker", newJString(Marker))
  add(query_602032, "EngineVersion", newJString(EngineVersion))
  add(query_602032, "Version", newJString(Version))
  result = call_602031.call(nil, query_602032, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602010(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602011, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_602076 = ref object of OpenApiRestCall_600410
proc url_PostDescribePendingMaintenanceActions_602078(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePendingMaintenanceActions_602077(path: JsonNode;
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
  var valid_602079 = query.getOrDefault("Action")
  valid_602079 = validateParameter(valid_602079, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_602079 != nil:
    section.add "Action", valid_602079
  var valid_602080 = query.getOrDefault("Version")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602080 != nil:
    section.add "Version", valid_602080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602081 = header.getOrDefault("X-Amz-Date")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Date", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Algorithm")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Algorithm", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-SignedHeaders", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Credential")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Credential", valid_602087
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
  var valid_602088 = formData.getOrDefault("Marker")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Marker", valid_602088
  var valid_602089 = formData.getOrDefault("ResourceIdentifier")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "ResourceIdentifier", valid_602089
  var valid_602090 = formData.getOrDefault("Filters")
  valid_602090 = validateParameter(valid_602090, JArray, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "Filters", valid_602090
  var valid_602091 = formData.getOrDefault("MaxRecords")
  valid_602091 = validateParameter(valid_602091, JInt, required = false, default = nil)
  if valid_602091 != nil:
    section.add "MaxRecords", valid_602091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_PostDescribePendingMaintenanceActions_602076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"))
  result = hook(call_602092, url, valid)

proc call*(call_602093: Call_PostDescribePendingMaintenanceActions_602076;
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
  var query_602094 = newJObject()
  var formData_602095 = newJObject()
  add(formData_602095, "Marker", newJString(Marker))
  add(query_602094, "Action", newJString(Action))
  add(formData_602095, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_602095.add "Filters", Filters
  add(formData_602095, "MaxRecords", newJInt(MaxRecords))
  add(query_602094, "Version", newJString(Version))
  result = call_602093.call(nil, query_602094, nil, formData_602095, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_602076(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_602077, base: "/",
    url: url_PostDescribePendingMaintenanceActions_602078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_602057 = ref object of OpenApiRestCall_600410
proc url_GetDescribePendingMaintenanceActions_602059(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePendingMaintenanceActions_602058(path: JsonNode;
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
  var valid_602060 = query.getOrDefault("MaxRecords")
  valid_602060 = validateParameter(valid_602060, JInt, required = false, default = nil)
  if valid_602060 != nil:
    section.add "MaxRecords", valid_602060
  var valid_602061 = query.getOrDefault("Filters")
  valid_602061 = validateParameter(valid_602061, JArray, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "Filters", valid_602061
  var valid_602062 = query.getOrDefault("ResourceIdentifier")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "ResourceIdentifier", valid_602062
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602063 = query.getOrDefault("Action")
  valid_602063 = validateParameter(valid_602063, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_602063 != nil:
    section.add "Action", valid_602063
  var valid_602064 = query.getOrDefault("Marker")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "Marker", valid_602064
  var valid_602065 = query.getOrDefault("Version")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602065 != nil:
    section.add "Version", valid_602065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602066 = header.getOrDefault("X-Amz-Date")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Date", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Content-Sha256", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Algorithm")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Algorithm", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-SignedHeaders", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Credential")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Credential", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_GetDescribePendingMaintenanceActions_602057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"))
  result = hook(call_602073, url, valid)

proc call*(call_602074: Call_GetDescribePendingMaintenanceActions_602057;
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
  var query_602075 = newJObject()
  add(query_602075, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602075.add "Filters", Filters
  add(query_602075, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_602075, "Action", newJString(Action))
  add(query_602075, "Marker", newJString(Marker))
  add(query_602075, "Version", newJString(Version))
  result = call_602074.call(nil, query_602075, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_602057(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_602058, base: "/",
    url: url_GetDescribePendingMaintenanceActions_602059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_602113 = ref object of OpenApiRestCall_600410
proc url_PostFailoverDBCluster_602115(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostFailoverDBCluster_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = query.getOrDefault("Action")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_602116 != nil:
    section.add "Action", valid_602116
  var valid_602117 = query.getOrDefault("Version")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602117 != nil:
    section.add "Version", valid_602117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602118 = header.getOrDefault("X-Amz-Date")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Date", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Security-Token")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Security-Token", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Algorithm")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Algorithm", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-SignedHeaders", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_602125 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602125
  var valid_602126 = formData.getOrDefault("DBClusterIdentifier")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "DBClusterIdentifier", valid_602126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602127: Call_PostFailoverDBCluster_602113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_602127.validator(path, query, header, formData, body)
  let scheme = call_602127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602127.url(scheme.get, call_602127.host, call_602127.base,
                         call_602127.route, valid.getOrDefault("path"))
  result = hook(call_602127, url, valid)

proc call*(call_602128: Call_PostFailoverDBCluster_602113;
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
  var query_602129 = newJObject()
  var formData_602130 = newJObject()
  add(query_602129, "Action", newJString(Action))
  add(formData_602130, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_602130, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602129, "Version", newJString(Version))
  result = call_602128.call(nil, query_602129, nil, formData_602130, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_602113(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_602114, base: "/",
    url: url_PostFailoverDBCluster_602115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_602096 = ref object of OpenApiRestCall_600410
proc url_GetFailoverDBCluster_602098(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFailoverDBCluster_602097(path: JsonNode; query: JsonNode;
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
  var valid_602099 = query.getOrDefault("DBClusterIdentifier")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "DBClusterIdentifier", valid_602099
  var valid_602100 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602100
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602101 = query.getOrDefault("Action")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_602101 != nil:
    section.add "Action", valid_602101
  var valid_602102 = query.getOrDefault("Version")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602102 != nil:
    section.add "Version", valid_602102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Security-Token")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Security-Token", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Content-Sha256", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-SignedHeaders", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602110: Call_GetFailoverDBCluster_602096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_602110.validator(path, query, header, formData, body)
  let scheme = call_602110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602110.url(scheme.get, call_602110.host, call_602110.base,
                         call_602110.route, valid.getOrDefault("path"))
  result = hook(call_602110, url, valid)

proc call*(call_602111: Call_GetFailoverDBCluster_602096;
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
  var query_602112 = newJObject()
  add(query_602112, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602112, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_602112, "Action", newJString(Action))
  add(query_602112, "Version", newJString(Version))
  result = call_602111.call(nil, query_602112, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_602096(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_602097, base: "/",
    url: url_GetFailoverDBCluster_602098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602148 = ref object of OpenApiRestCall_600410
proc url_PostListTagsForResource_602150(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602149(path: JsonNode; query: JsonNode;
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
  var valid_602151 = query.getOrDefault("Action")
  valid_602151 = validateParameter(valid_602151, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602151 != nil:
    section.add "Action", valid_602151
  var valid_602152 = query.getOrDefault("Version")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602152 != nil:
    section.add "Version", valid_602152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602153 = header.getOrDefault("X-Amz-Date")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Date", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Content-Sha256", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Algorithm")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Algorithm", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Signature", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-SignedHeaders", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Credential")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Credential", valid_602159
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_602160 = formData.getOrDefault("Filters")
  valid_602160 = validateParameter(valid_602160, JArray, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "Filters", valid_602160
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602161 = formData.getOrDefault("ResourceName")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "ResourceName", valid_602161
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_PostListTagsForResource_602148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"))
  result = hook(call_602162, url, valid)

proc call*(call_602163: Call_PostListTagsForResource_602148; ResourceName: string;
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
  var query_602164 = newJObject()
  var formData_602165 = newJObject()
  add(query_602164, "Action", newJString(Action))
  if Filters != nil:
    formData_602165.add "Filters", Filters
  add(formData_602165, "ResourceName", newJString(ResourceName))
  add(query_602164, "Version", newJString(Version))
  result = call_602163.call(nil, query_602164, nil, formData_602165, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602148(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602149, base: "/",
    url: url_PostListTagsForResource_602150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602131 = ref object of OpenApiRestCall_600410
proc url_GetListTagsForResource_602133(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602132(path: JsonNode; query: JsonNode;
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
  var valid_602134 = query.getOrDefault("Filters")
  valid_602134 = validateParameter(valid_602134, JArray, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "Filters", valid_602134
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_602135 = query.getOrDefault("ResourceName")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "ResourceName", valid_602135
  var valid_602136 = query.getOrDefault("Action")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602136 != nil:
    section.add "Action", valid_602136
  var valid_602137 = query.getOrDefault("Version")
  valid_602137 = validateParameter(valid_602137, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602137 != nil:
    section.add "Version", valid_602137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602138 = header.getOrDefault("X-Amz-Date")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Date", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Algorithm")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Algorithm", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Signature")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Signature", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-SignedHeaders", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602145: Call_GetListTagsForResource_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_602145.validator(path, query, header, formData, body)
  let scheme = call_602145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602145.url(scheme.get, call_602145.host, call_602145.base,
                         call_602145.route, valid.getOrDefault("path"))
  result = hook(call_602145, url, valid)

proc call*(call_602146: Call_GetListTagsForResource_602131; ResourceName: string;
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
  var query_602147 = newJObject()
  if Filters != nil:
    query_602147.add "Filters", Filters
  add(query_602147, "ResourceName", newJString(ResourceName))
  add(query_602147, "Action", newJString(Action))
  add(query_602147, "Version", newJString(Version))
  result = call_602146.call(nil, query_602147, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602131(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602132, base: "/",
    url: url_GetListTagsForResource_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_602195 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBCluster_602197(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBCluster_602196(path: JsonNode; query: JsonNode;
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
  var valid_602198 = query.getOrDefault("Action")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_602198 != nil:
    section.add "Action", valid_602198
  var valid_602199 = query.getOrDefault("Version")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602199 != nil:
    section.add "Version", valid_602199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602200 = header.getOrDefault("X-Amz-Date")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Date", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Security-Token")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Security-Token", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Content-Sha256", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Algorithm")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Algorithm", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Signature")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Signature", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-SignedHeaders", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Credential")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Credential", valid_602206
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
  var valid_602207 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_602207 = validateParameter(valid_602207, JArray, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_602207
  var valid_602208 = formData.getOrDefault("ApplyImmediately")
  valid_602208 = validateParameter(valid_602208, JBool, required = false, default = nil)
  if valid_602208 != nil:
    section.add "ApplyImmediately", valid_602208
  var valid_602209 = formData.getOrDefault("Port")
  valid_602209 = validateParameter(valid_602209, JInt, required = false, default = nil)
  if valid_602209 != nil:
    section.add "Port", valid_602209
  var valid_602210 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602210 = validateParameter(valid_602210, JArray, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "VpcSecurityGroupIds", valid_602210
  var valid_602211 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602211 = validateParameter(valid_602211, JInt, required = false, default = nil)
  if valid_602211 != nil:
    section.add "BackupRetentionPeriod", valid_602211
  var valid_602212 = formData.getOrDefault("MasterUserPassword")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "MasterUserPassword", valid_602212
  var valid_602213 = formData.getOrDefault("DeletionProtection")
  valid_602213 = validateParameter(valid_602213, JBool, required = false, default = nil)
  if valid_602213 != nil:
    section.add "DeletionProtection", valid_602213
  var valid_602214 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "NewDBClusterIdentifier", valid_602214
  var valid_602215 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_602215 = validateParameter(valid_602215, JArray, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_602215
  var valid_602216 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "DBClusterParameterGroupName", valid_602216
  var valid_602217 = formData.getOrDefault("PreferredBackupWindow")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "PreferredBackupWindow", valid_602217
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602218 = formData.getOrDefault("DBClusterIdentifier")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = nil)
  if valid_602218 != nil:
    section.add "DBClusterIdentifier", valid_602218
  var valid_602219 = formData.getOrDefault("EngineVersion")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "EngineVersion", valid_602219
  var valid_602220 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "PreferredMaintenanceWindow", valid_602220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602221: Call_PostModifyDBCluster_602195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_602221.validator(path, query, header, formData, body)
  let scheme = call_602221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602221.url(scheme.get, call_602221.host, call_602221.base,
                         call_602221.route, valid.getOrDefault("path"))
  result = hook(call_602221, url, valid)

proc call*(call_602222: Call_PostModifyDBCluster_602195;
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
  var query_602223 = newJObject()
  var formData_602224 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_602224.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_602224, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602224, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_602224.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602224, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602224, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602224, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_602224, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_602224.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_602223, "Action", newJString(Action))
  add(formData_602224, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_602224, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602224, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_602224, "EngineVersion", newJString(EngineVersion))
  add(query_602223, "Version", newJString(Version))
  add(formData_602224, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_602222.call(nil, query_602223, nil, formData_602224, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_602195(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_602196, base: "/",
    url: url_PostModifyDBCluster_602197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_602166 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBCluster_602168(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBCluster_602167(path: JsonNode; query: JsonNode;
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
  var valid_602169 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "PreferredMaintenanceWindow", valid_602169
  var valid_602170 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "DBClusterParameterGroupName", valid_602170
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602171 = query.getOrDefault("DBClusterIdentifier")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = nil)
  if valid_602171 != nil:
    section.add "DBClusterIdentifier", valid_602171
  var valid_602172 = query.getOrDefault("MasterUserPassword")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "MasterUserPassword", valid_602172
  var valid_602173 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_602173 = validateParameter(valid_602173, JArray, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_602173
  var valid_602174 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602174 = validateParameter(valid_602174, JArray, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "VpcSecurityGroupIds", valid_602174
  var valid_602175 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_602175 = validateParameter(valid_602175, JArray, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_602175
  var valid_602176 = query.getOrDefault("BackupRetentionPeriod")
  valid_602176 = validateParameter(valid_602176, JInt, required = false, default = nil)
  if valid_602176 != nil:
    section.add "BackupRetentionPeriod", valid_602176
  var valid_602177 = query.getOrDefault("NewDBClusterIdentifier")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "NewDBClusterIdentifier", valid_602177
  var valid_602178 = query.getOrDefault("DeletionProtection")
  valid_602178 = validateParameter(valid_602178, JBool, required = false, default = nil)
  if valid_602178 != nil:
    section.add "DeletionProtection", valid_602178
  var valid_602179 = query.getOrDefault("Action")
  valid_602179 = validateParameter(valid_602179, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_602179 != nil:
    section.add "Action", valid_602179
  var valid_602180 = query.getOrDefault("EngineVersion")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "EngineVersion", valid_602180
  var valid_602181 = query.getOrDefault("Port")
  valid_602181 = validateParameter(valid_602181, JInt, required = false, default = nil)
  if valid_602181 != nil:
    section.add "Port", valid_602181
  var valid_602182 = query.getOrDefault("PreferredBackupWindow")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "PreferredBackupWindow", valid_602182
  var valid_602183 = query.getOrDefault("Version")
  valid_602183 = validateParameter(valid_602183, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602183 != nil:
    section.add "Version", valid_602183
  var valid_602184 = query.getOrDefault("ApplyImmediately")
  valid_602184 = validateParameter(valid_602184, JBool, required = false, default = nil)
  if valid_602184 != nil:
    section.add "ApplyImmediately", valid_602184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602185 = header.getOrDefault("X-Amz-Date")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Date", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Security-Token")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Security-Token", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Content-Sha256", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Algorithm")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Algorithm", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Signature")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Signature", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-SignedHeaders", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Credential")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Credential", valid_602191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602192: Call_GetModifyDBCluster_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_602192.validator(path, query, header, formData, body)
  let scheme = call_602192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602192.url(scheme.get, call_602192.host, call_602192.base,
                         call_602192.route, valid.getOrDefault("path"))
  result = hook(call_602192, url, valid)

proc call*(call_602193: Call_GetModifyDBCluster_602166;
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
  var query_602194 = newJObject()
  add(query_602194, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602194, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602194, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602194, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_602194.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_602194.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_602194.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_602194, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602194, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_602194, "DeletionProtection", newJBool(DeletionProtection))
  add(query_602194, "Action", newJString(Action))
  add(query_602194, "EngineVersion", newJString(EngineVersion))
  add(query_602194, "Port", newJInt(Port))
  add(query_602194, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602194, "Version", newJString(Version))
  add(query_602194, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602193.call(nil, query_602194, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_602166(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_602167,
    base: "/", url: url_GetModifyDBCluster_602168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_602242 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBClusterParameterGroup_602244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterParameterGroup_602243(path: JsonNode;
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
  var valid_602245 = query.getOrDefault("Action")
  valid_602245 = validateParameter(valid_602245, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_602245 != nil:
    section.add "Action", valid_602245
  var valid_602246 = query.getOrDefault("Version")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602246 != nil:
    section.add "Version", valid_602246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Security-Token")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Security-Token", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Content-Sha256", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Signature")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Signature", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-SignedHeaders", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_602254 = formData.getOrDefault("Parameters")
  valid_602254 = validateParameter(valid_602254, JArray, required = true, default = nil)
  if valid_602254 != nil:
    section.add "Parameters", valid_602254
  var valid_602255 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602255 = validateParameter(valid_602255, JString, required = true,
                                 default = nil)
  if valid_602255 != nil:
    section.add "DBClusterParameterGroupName", valid_602255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602256: Call_PostModifyDBClusterParameterGroup_602242;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_602256.validator(path, query, header, formData, body)
  let scheme = call_602256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602256.url(scheme.get, call_602256.host, call_602256.base,
                         call_602256.route, valid.getOrDefault("path"))
  result = hook(call_602256, url, valid)

proc call*(call_602257: Call_PostModifyDBClusterParameterGroup_602242;
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
  var query_602258 = newJObject()
  var formData_602259 = newJObject()
  if Parameters != nil:
    formData_602259.add "Parameters", Parameters
  add(query_602258, "Action", newJString(Action))
  add(formData_602259, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602258, "Version", newJString(Version))
  result = call_602257.call(nil, query_602258, nil, formData_602259, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_602242(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_602243, base: "/",
    url: url_PostModifyDBClusterParameterGroup_602244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_602225 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBClusterParameterGroup_602227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterParameterGroup_602226(path: JsonNode;
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
  var valid_602228 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "DBClusterParameterGroupName", valid_602228
  var valid_602229 = query.getOrDefault("Parameters")
  valid_602229 = validateParameter(valid_602229, JArray, required = true, default = nil)
  if valid_602229 != nil:
    section.add "Parameters", valid_602229
  var valid_602230 = query.getOrDefault("Action")
  valid_602230 = validateParameter(valid_602230, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_602230 != nil:
    section.add "Action", valid_602230
  var valid_602231 = query.getOrDefault("Version")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602231 != nil:
    section.add "Version", valid_602231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602232 = header.getOrDefault("X-Amz-Date")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Date", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Security-Token")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Security-Token", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Algorithm")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Algorithm", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Signature")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Signature", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602239: Call_GetModifyDBClusterParameterGroup_602225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_602239.validator(path, query, header, formData, body)
  let scheme = call_602239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602239.url(scheme.get, call_602239.host, call_602239.base,
                         call_602239.route, valid.getOrDefault("path"))
  result = hook(call_602239, url, valid)

proc call*(call_602240: Call_GetModifyDBClusterParameterGroup_602225;
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
  var query_602241 = newJObject()
  add(query_602241, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_602241.add "Parameters", Parameters
  add(query_602241, "Action", newJString(Action))
  add(query_602241, "Version", newJString(Version))
  result = call_602240.call(nil, query_602241, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_602225(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_602226, base: "/",
    url: url_GetModifyDBClusterParameterGroup_602227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_602279 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBClusterSnapshotAttribute_602281(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterSnapshotAttribute_602280(path: JsonNode;
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
  var valid_602282 = query.getOrDefault("Action")
  valid_602282 = validateParameter(valid_602282, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_602282 != nil:
    section.add "Action", valid_602282
  var valid_602283 = query.getOrDefault("Version")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602283 != nil:
    section.add "Version", valid_602283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602284 = header.getOrDefault("X-Amz-Date")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Date", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Security-Token")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Security-Token", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Algorithm")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Algorithm", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Signature")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Signature", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Credential")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Credential", valid_602290
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
  var valid_602291 = formData.getOrDefault("AttributeName")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = nil)
  if valid_602291 != nil:
    section.add "AttributeName", valid_602291
  var valid_602292 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = nil)
  if valid_602292 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602292
  var valid_602293 = formData.getOrDefault("ValuesToRemove")
  valid_602293 = validateParameter(valid_602293, JArray, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "ValuesToRemove", valid_602293
  var valid_602294 = formData.getOrDefault("ValuesToAdd")
  valid_602294 = validateParameter(valid_602294, JArray, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "ValuesToAdd", valid_602294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602295: Call_PostModifyDBClusterSnapshotAttribute_602279;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_602295.validator(path, query, header, formData, body)
  let scheme = call_602295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602295.url(scheme.get, call_602295.host, call_602295.base,
                         call_602295.route, valid.getOrDefault("path"))
  result = hook(call_602295, url, valid)

proc call*(call_602296: Call_PostModifyDBClusterSnapshotAttribute_602279;
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
  var query_602297 = newJObject()
  var formData_602298 = newJObject()
  add(formData_602298, "AttributeName", newJString(AttributeName))
  add(formData_602298, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602297, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_602298.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_602298.add "ValuesToAdd", ValuesToAdd
  add(query_602297, "Version", newJString(Version))
  result = call_602296.call(nil, query_602297, nil, formData_602298, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_602279(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_602280, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_602281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_602260 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBClusterSnapshotAttribute_602262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterSnapshotAttribute_602261(path: JsonNode;
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
  var valid_602263 = query.getOrDefault("AttributeName")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = nil)
  if valid_602263 != nil:
    section.add "AttributeName", valid_602263
  var valid_602264 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602264
  var valid_602265 = query.getOrDefault("ValuesToAdd")
  valid_602265 = validateParameter(valid_602265, JArray, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "ValuesToAdd", valid_602265
  var valid_602266 = query.getOrDefault("Action")
  valid_602266 = validateParameter(valid_602266, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_602266 != nil:
    section.add "Action", valid_602266
  var valid_602267 = query.getOrDefault("ValuesToRemove")
  valid_602267 = validateParameter(valid_602267, JArray, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "ValuesToRemove", valid_602267
  var valid_602268 = query.getOrDefault("Version")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602268 != nil:
    section.add "Version", valid_602268
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602269 = header.getOrDefault("X-Amz-Date")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Date", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Security-Token")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Security-Token", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Content-Sha256", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Algorithm")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Algorithm", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Signature")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Signature", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_GetModifyDBClusterSnapshotAttribute_602260;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"))
  result = hook(call_602276, url, valid)

proc call*(call_602277: Call_GetModifyDBClusterSnapshotAttribute_602260;
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
  var query_602278 = newJObject()
  add(query_602278, "AttributeName", newJString(AttributeName))
  add(query_602278, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_602278.add "ValuesToAdd", ValuesToAdd
  add(query_602278, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_602278.add "ValuesToRemove", ValuesToRemove
  add(query_602278, "Version", newJString(Version))
  result = call_602277.call(nil, query_602278, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_602260(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_602261, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_602262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602321 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBInstance_602323(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_602322(path: JsonNode; query: JsonNode;
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
  var valid_602324 = query.getOrDefault("Action")
  valid_602324 = validateParameter(valid_602324, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602324 != nil:
    section.add "Action", valid_602324
  var valid_602325 = query.getOrDefault("Version")
  valid_602325 = validateParameter(valid_602325, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602325 != nil:
    section.add "Version", valid_602325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602326 = header.getOrDefault("X-Amz-Date")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Date", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Security-Token")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Security-Token", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Algorithm")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Algorithm", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-SignedHeaders", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Credential")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Credential", valid_602332
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
  var valid_602333 = formData.getOrDefault("ApplyImmediately")
  valid_602333 = validateParameter(valid_602333, JBool, required = false, default = nil)
  if valid_602333 != nil:
    section.add "ApplyImmediately", valid_602333
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602334 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602334 = validateParameter(valid_602334, JString, required = true,
                                 default = nil)
  if valid_602334 != nil:
    section.add "DBInstanceIdentifier", valid_602334
  var valid_602335 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "NewDBInstanceIdentifier", valid_602335
  var valid_602336 = formData.getOrDefault("PromotionTier")
  valid_602336 = validateParameter(valid_602336, JInt, required = false, default = nil)
  if valid_602336 != nil:
    section.add "PromotionTier", valid_602336
  var valid_602337 = formData.getOrDefault("DBInstanceClass")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "DBInstanceClass", valid_602337
  var valid_602338 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602338 = validateParameter(valid_602338, JBool, required = false, default = nil)
  if valid_602338 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602338
  var valid_602339 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "PreferredMaintenanceWindow", valid_602339
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_PostModifyDBInstance_602321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"))
  result = hook(call_602340, url, valid)

proc call*(call_602341: Call_PostModifyDBInstance_602321;
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
  var query_602342 = newJObject()
  var formData_602343 = newJObject()
  add(formData_602343, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602343, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602343, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_602342, "Action", newJString(Action))
  add(formData_602343, "PromotionTier", newJInt(PromotionTier))
  add(formData_602343, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602343, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602342, "Version", newJString(Version))
  add(formData_602343, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_602341.call(nil, query_602342, nil, formData_602343, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602321(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602322, base: "/",
    url: url_PostModifyDBInstance_602323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602299 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBInstance_602301(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_602300(path: JsonNode; query: JsonNode;
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
  var valid_602302 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "PreferredMaintenanceWindow", valid_602302
  var valid_602303 = query.getOrDefault("PromotionTier")
  valid_602303 = validateParameter(valid_602303, JInt, required = false, default = nil)
  if valid_602303 != nil:
    section.add "PromotionTier", valid_602303
  var valid_602304 = query.getOrDefault("DBInstanceClass")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "DBInstanceClass", valid_602304
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602305 = query.getOrDefault("Action")
  valid_602305 = validateParameter(valid_602305, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602305 != nil:
    section.add "Action", valid_602305
  var valid_602306 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "NewDBInstanceIdentifier", valid_602306
  var valid_602307 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602307 = validateParameter(valid_602307, JBool, required = false, default = nil)
  if valid_602307 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602307
  var valid_602308 = query.getOrDefault("Version")
  valid_602308 = validateParameter(valid_602308, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602308 != nil:
    section.add "Version", valid_602308
  var valid_602309 = query.getOrDefault("DBInstanceIdentifier")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = nil)
  if valid_602309 != nil:
    section.add "DBInstanceIdentifier", valid_602309
  var valid_602310 = query.getOrDefault("ApplyImmediately")
  valid_602310 = validateParameter(valid_602310, JBool, required = false, default = nil)
  if valid_602310 != nil:
    section.add "ApplyImmediately", valid_602310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602311 = header.getOrDefault("X-Amz-Date")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Date", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Security-Token")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Security-Token", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Algorithm")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Algorithm", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602318: Call_GetModifyDBInstance_602299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_602318.validator(path, query, header, formData, body)
  let scheme = call_602318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602318.url(scheme.get, call_602318.host, call_602318.base,
                         call_602318.route, valid.getOrDefault("path"))
  result = hook(call_602318, url, valid)

proc call*(call_602319: Call_GetModifyDBInstance_602299;
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
  var query_602320 = newJObject()
  add(query_602320, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602320, "PromotionTier", newJInt(PromotionTier))
  add(query_602320, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602320, "Action", newJString(Action))
  add(query_602320, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602320, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602320, "Version", newJString(Version))
  add(query_602320, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602320, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602319.call(nil, query_602320, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602299(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602300, base: "/",
    url: url_GetModifyDBInstance_602301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602362 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBSubnetGroup_602364(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_602363(path: JsonNode; query: JsonNode;
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
  var valid_602365 = query.getOrDefault("Action")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602365 != nil:
    section.add "Action", valid_602365
  var valid_602366 = query.getOrDefault("Version")
  valid_602366 = validateParameter(valid_602366, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602366 != nil:
    section.add "Version", valid_602366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Content-Sha256", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Algorithm")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Algorithm", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-SignedHeaders", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Credential")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Credential", valid_602373
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
  var valid_602374 = formData.getOrDefault("DBSubnetGroupName")
  valid_602374 = validateParameter(valid_602374, JString, required = true,
                                 default = nil)
  if valid_602374 != nil:
    section.add "DBSubnetGroupName", valid_602374
  var valid_602375 = formData.getOrDefault("SubnetIds")
  valid_602375 = validateParameter(valid_602375, JArray, required = true, default = nil)
  if valid_602375 != nil:
    section.add "SubnetIds", valid_602375
  var valid_602376 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "DBSubnetGroupDescription", valid_602376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602377: Call_PostModifyDBSubnetGroup_602362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_602377.validator(path, query, header, formData, body)
  let scheme = call_602377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602377.url(scheme.get, call_602377.host, call_602377.base,
                         call_602377.route, valid.getOrDefault("path"))
  result = hook(call_602377, url, valid)

proc call*(call_602378: Call_PostModifyDBSubnetGroup_602362;
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
  var query_602379 = newJObject()
  var formData_602380 = newJObject()
  add(formData_602380, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602380.add "SubnetIds", SubnetIds
  add(query_602379, "Action", newJString(Action))
  add(formData_602380, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602379, "Version", newJString(Version))
  result = call_602378.call(nil, query_602379, nil, formData_602380, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602362(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602363, base: "/",
    url: url_PostModifyDBSubnetGroup_602364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602344 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBSubnetGroup_602346(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_602345(path: JsonNode; query: JsonNode;
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
  var valid_602347 = query.getOrDefault("Action")
  valid_602347 = validateParameter(valid_602347, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602347 != nil:
    section.add "Action", valid_602347
  var valid_602348 = query.getOrDefault("DBSubnetGroupName")
  valid_602348 = validateParameter(valid_602348, JString, required = true,
                                 default = nil)
  if valid_602348 != nil:
    section.add "DBSubnetGroupName", valid_602348
  var valid_602349 = query.getOrDefault("SubnetIds")
  valid_602349 = validateParameter(valid_602349, JArray, required = true, default = nil)
  if valid_602349 != nil:
    section.add "SubnetIds", valid_602349
  var valid_602350 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "DBSubnetGroupDescription", valid_602350
  var valid_602351 = query.getOrDefault("Version")
  valid_602351 = validateParameter(valid_602351, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602351 != nil:
    section.add "Version", valid_602351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602352 = header.getOrDefault("X-Amz-Date")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Date", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Security-Token")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Security-Token", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Content-Sha256", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Algorithm")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Algorithm", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Signature")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Signature", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-SignedHeaders", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Credential")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Credential", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602359: Call_GetModifyDBSubnetGroup_602344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_602359.validator(path, query, header, formData, body)
  let scheme = call_602359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602359.url(scheme.get, call_602359.host, call_602359.base,
                         call_602359.route, valid.getOrDefault("path"))
  result = hook(call_602359, url, valid)

proc call*(call_602360: Call_GetModifyDBSubnetGroup_602344;
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
  var query_602361 = newJObject()
  add(query_602361, "Action", newJString(Action))
  add(query_602361, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602361.add "SubnetIds", SubnetIds
  add(query_602361, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602361, "Version", newJString(Version))
  result = call_602360.call(nil, query_602361, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602344(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602345, base: "/",
    url: url_GetModifyDBSubnetGroup_602346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602398 = ref object of OpenApiRestCall_600410
proc url_PostRebootDBInstance_602400(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_602399(path: JsonNode; query: JsonNode;
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
  var valid_602401 = query.getOrDefault("Action")
  valid_602401 = validateParameter(valid_602401, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602401 != nil:
    section.add "Action", valid_602401
  var valid_602402 = query.getOrDefault("Version")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602402 != nil:
    section.add "Version", valid_602402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602403 = header.getOrDefault("X-Amz-Date")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Date", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Security-Token")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Security-Token", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Content-Sha256", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Algorithm")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Algorithm", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Signature")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Signature", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-SignedHeaders", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Credential")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Credential", valid_602409
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602410 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602410 = validateParameter(valid_602410, JString, required = true,
                                 default = nil)
  if valid_602410 != nil:
    section.add "DBInstanceIdentifier", valid_602410
  var valid_602411 = formData.getOrDefault("ForceFailover")
  valid_602411 = validateParameter(valid_602411, JBool, required = false, default = nil)
  if valid_602411 != nil:
    section.add "ForceFailover", valid_602411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602412: Call_PostRebootDBInstance_602398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_602412.validator(path, query, header, formData, body)
  let scheme = call_602412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602412.url(scheme.get, call_602412.host, call_602412.base,
                         call_602412.route, valid.getOrDefault("path"))
  result = hook(call_602412, url, valid)

proc call*(call_602413: Call_PostRebootDBInstance_602398;
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
  var query_602414 = newJObject()
  var formData_602415 = newJObject()
  add(formData_602415, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602414, "Action", newJString(Action))
  add(formData_602415, "ForceFailover", newJBool(ForceFailover))
  add(query_602414, "Version", newJString(Version))
  result = call_602413.call(nil, query_602414, nil, formData_602415, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602398(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602399, base: "/",
    url: url_PostRebootDBInstance_602400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602381 = ref object of OpenApiRestCall_600410
proc url_GetRebootDBInstance_602383(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_602382(path: JsonNode; query: JsonNode;
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
  var valid_602384 = query.getOrDefault("Action")
  valid_602384 = validateParameter(valid_602384, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602384 != nil:
    section.add "Action", valid_602384
  var valid_602385 = query.getOrDefault("ForceFailover")
  valid_602385 = validateParameter(valid_602385, JBool, required = false, default = nil)
  if valid_602385 != nil:
    section.add "ForceFailover", valid_602385
  var valid_602386 = query.getOrDefault("Version")
  valid_602386 = validateParameter(valid_602386, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602386 != nil:
    section.add "Version", valid_602386
  var valid_602387 = query.getOrDefault("DBInstanceIdentifier")
  valid_602387 = validateParameter(valid_602387, JString, required = true,
                                 default = nil)
  if valid_602387 != nil:
    section.add "DBInstanceIdentifier", valid_602387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602388 = header.getOrDefault("X-Amz-Date")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Date", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Security-Token")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Security-Token", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Content-Sha256", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Algorithm")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Algorithm", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Signature")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Signature", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-SignedHeaders", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Credential")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Credential", valid_602394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602395: Call_GetRebootDBInstance_602381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_602395.validator(path, query, header, formData, body)
  let scheme = call_602395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602395.url(scheme.get, call_602395.host, call_602395.base,
                         call_602395.route, valid.getOrDefault("path"))
  result = hook(call_602395, url, valid)

proc call*(call_602396: Call_GetRebootDBInstance_602381;
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
  var query_602397 = newJObject()
  add(query_602397, "Action", newJString(Action))
  add(query_602397, "ForceFailover", newJBool(ForceFailover))
  add(query_602397, "Version", newJString(Version))
  add(query_602397, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602396.call(nil, query_602397, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602381(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602382, base: "/",
    url: url_GetRebootDBInstance_602383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602433 = ref object of OpenApiRestCall_600410
proc url_PostRemoveTagsFromResource_602435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_602434(path: JsonNode; query: JsonNode;
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
  var valid_602436 = query.getOrDefault("Action")
  valid_602436 = validateParameter(valid_602436, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602436 != nil:
    section.add "Action", valid_602436
  var valid_602437 = query.getOrDefault("Version")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602437 != nil:
    section.add "Version", valid_602437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602438 = header.getOrDefault("X-Amz-Date")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Date", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Security-Token")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Security-Token", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Content-Sha256", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Algorithm")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Algorithm", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-SignedHeaders", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Credential")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Credential", valid_602444
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602445 = formData.getOrDefault("TagKeys")
  valid_602445 = validateParameter(valid_602445, JArray, required = true, default = nil)
  if valid_602445 != nil:
    section.add "TagKeys", valid_602445
  var valid_602446 = formData.getOrDefault("ResourceName")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "ResourceName", valid_602446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602447: Call_PostRemoveTagsFromResource_602433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_602447.validator(path, query, header, formData, body)
  let scheme = call_602447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602447.url(scheme.get, call_602447.host, call_602447.base,
                         call_602447.route, valid.getOrDefault("path"))
  result = hook(call_602447, url, valid)

proc call*(call_602448: Call_PostRemoveTagsFromResource_602433; TagKeys: JsonNode;
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
  var query_602449 = newJObject()
  var formData_602450 = newJObject()
  add(query_602449, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602450.add "TagKeys", TagKeys
  add(formData_602450, "ResourceName", newJString(ResourceName))
  add(query_602449, "Version", newJString(Version))
  result = call_602448.call(nil, query_602449, nil, formData_602450, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602433(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602434, base: "/",
    url: url_PostRemoveTagsFromResource_602435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602416 = ref object of OpenApiRestCall_600410
proc url_GetRemoveTagsFromResource_602418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_602417(path: JsonNode; query: JsonNode;
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
  var valid_602419 = query.getOrDefault("ResourceName")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = nil)
  if valid_602419 != nil:
    section.add "ResourceName", valid_602419
  var valid_602420 = query.getOrDefault("Action")
  valid_602420 = validateParameter(valid_602420, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602420 != nil:
    section.add "Action", valid_602420
  var valid_602421 = query.getOrDefault("TagKeys")
  valid_602421 = validateParameter(valid_602421, JArray, required = true, default = nil)
  if valid_602421 != nil:
    section.add "TagKeys", valid_602421
  var valid_602422 = query.getOrDefault("Version")
  valid_602422 = validateParameter(valid_602422, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602422 != nil:
    section.add "Version", valid_602422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602423 = header.getOrDefault("X-Amz-Date")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Date", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Algorithm")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Algorithm", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-SignedHeaders", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Credential")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Credential", valid_602429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602430: Call_GetRemoveTagsFromResource_602416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_602430.validator(path, query, header, formData, body)
  let scheme = call_602430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602430.url(scheme.get, call_602430.host, call_602430.base,
                         call_602430.route, valid.getOrDefault("path"))
  result = hook(call_602430, url, valid)

proc call*(call_602431: Call_GetRemoveTagsFromResource_602416;
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
  var query_602432 = newJObject()
  add(query_602432, "ResourceName", newJString(ResourceName))
  add(query_602432, "Action", newJString(Action))
  if TagKeys != nil:
    query_602432.add "TagKeys", TagKeys
  add(query_602432, "Version", newJString(Version))
  result = call_602431.call(nil, query_602432, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602416(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602417, base: "/",
    url: url_GetRemoveTagsFromResource_602418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_602469 = ref object of OpenApiRestCall_600410
proc url_PostResetDBClusterParameterGroup_602471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBClusterParameterGroup_602470(path: JsonNode;
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
  var valid_602472 = query.getOrDefault("Action")
  valid_602472 = validateParameter(valid_602472, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_602472 != nil:
    section.add "Action", valid_602472
  var valid_602473 = query.getOrDefault("Version")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602473 != nil:
    section.add "Version", valid_602473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602474 = header.getOrDefault("X-Amz-Date")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Date", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Security-Token")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Security-Token", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Content-Sha256", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Algorithm")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Algorithm", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Signature")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Signature", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-SignedHeaders", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Credential")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Credential", valid_602480
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_602481 = formData.getOrDefault("Parameters")
  valid_602481 = validateParameter(valid_602481, JArray, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "Parameters", valid_602481
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_602482 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602482 = validateParameter(valid_602482, JString, required = true,
                                 default = nil)
  if valid_602482 != nil:
    section.add "DBClusterParameterGroupName", valid_602482
  var valid_602483 = formData.getOrDefault("ResetAllParameters")
  valid_602483 = validateParameter(valid_602483, JBool, required = false, default = nil)
  if valid_602483 != nil:
    section.add "ResetAllParameters", valid_602483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602484: Call_PostResetDBClusterParameterGroup_602469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_602484.validator(path, query, header, formData, body)
  let scheme = call_602484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602484.url(scheme.get, call_602484.host, call_602484.base,
                         call_602484.route, valid.getOrDefault("path"))
  result = hook(call_602484, url, valid)

proc call*(call_602485: Call_PostResetDBClusterParameterGroup_602469;
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
  var query_602486 = newJObject()
  var formData_602487 = newJObject()
  if Parameters != nil:
    formData_602487.add "Parameters", Parameters
  add(query_602486, "Action", newJString(Action))
  add(formData_602487, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_602487, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602486, "Version", newJString(Version))
  result = call_602485.call(nil, query_602486, nil, formData_602487, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_602469(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_602470, base: "/",
    url: url_PostResetDBClusterParameterGroup_602471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_602451 = ref object of OpenApiRestCall_600410
proc url_GetResetDBClusterParameterGroup_602453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBClusterParameterGroup_602452(path: JsonNode;
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
  var valid_602454 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602454 = validateParameter(valid_602454, JString, required = true,
                                 default = nil)
  if valid_602454 != nil:
    section.add "DBClusterParameterGroupName", valid_602454
  var valid_602455 = query.getOrDefault("Parameters")
  valid_602455 = validateParameter(valid_602455, JArray, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "Parameters", valid_602455
  var valid_602456 = query.getOrDefault("Action")
  valid_602456 = validateParameter(valid_602456, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_602456 != nil:
    section.add "Action", valid_602456
  var valid_602457 = query.getOrDefault("ResetAllParameters")
  valid_602457 = validateParameter(valid_602457, JBool, required = false, default = nil)
  if valid_602457 != nil:
    section.add "ResetAllParameters", valid_602457
  var valid_602458 = query.getOrDefault("Version")
  valid_602458 = validateParameter(valid_602458, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602458 != nil:
    section.add "Version", valid_602458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Security-Token")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Security-Token", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Content-Sha256", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Signature")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Signature", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-SignedHeaders", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602466: Call_GetResetDBClusterParameterGroup_602451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_602466.validator(path, query, header, formData, body)
  let scheme = call_602466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602466.url(scheme.get, call_602466.host, call_602466.base,
                         call_602466.route, valid.getOrDefault("path"))
  result = hook(call_602466, url, valid)

proc call*(call_602467: Call_GetResetDBClusterParameterGroup_602451;
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
  var query_602468 = newJObject()
  add(query_602468, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_602468.add "Parameters", Parameters
  add(query_602468, "Action", newJString(Action))
  add(query_602468, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602468, "Version", newJString(Version))
  result = call_602467.call(nil, query_602468, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_602451(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_602452, base: "/",
    url: url_GetResetDBClusterParameterGroup_602453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_602515 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBClusterFromSnapshot_602517(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterFromSnapshot_602516(path: JsonNode;
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
  var valid_602518 = query.getOrDefault("Action")
  valid_602518 = validateParameter(valid_602518, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_602518 != nil:
    section.add "Action", valid_602518
  var valid_602519 = query.getOrDefault("Version")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602519 != nil:
    section.add "Version", valid_602519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602520 = header.getOrDefault("X-Amz-Date")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Date", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Security-Token")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Security-Token", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Content-Sha256", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Algorithm")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Algorithm", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Signature")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Signature", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-SignedHeaders", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Credential")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Credential", valid_602526
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
  var valid_602527 = formData.getOrDefault("Port")
  valid_602527 = validateParameter(valid_602527, JInt, required = false, default = nil)
  if valid_602527 != nil:
    section.add "Port", valid_602527
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_602528 = formData.getOrDefault("Engine")
  valid_602528 = validateParameter(valid_602528, JString, required = true,
                                 default = nil)
  if valid_602528 != nil:
    section.add "Engine", valid_602528
  var valid_602529 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602529 = validateParameter(valid_602529, JArray, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "VpcSecurityGroupIds", valid_602529
  var valid_602530 = formData.getOrDefault("Tags")
  valid_602530 = validateParameter(valid_602530, JArray, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "Tags", valid_602530
  var valid_602531 = formData.getOrDefault("DeletionProtection")
  valid_602531 = validateParameter(valid_602531, JBool, required = false, default = nil)
  if valid_602531 != nil:
    section.add "DeletionProtection", valid_602531
  var valid_602532 = formData.getOrDefault("DBSubnetGroupName")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "DBSubnetGroupName", valid_602532
  var valid_602533 = formData.getOrDefault("AvailabilityZones")
  valid_602533 = validateParameter(valid_602533, JArray, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "AvailabilityZones", valid_602533
  var valid_602534 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_602534 = validateParameter(valid_602534, JArray, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602534
  var valid_602535 = formData.getOrDefault("KmsKeyId")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "KmsKeyId", valid_602535
  var valid_602536 = formData.getOrDefault("SnapshotIdentifier")
  valid_602536 = validateParameter(valid_602536, JString, required = true,
                                 default = nil)
  if valid_602536 != nil:
    section.add "SnapshotIdentifier", valid_602536
  var valid_602537 = formData.getOrDefault("DBClusterIdentifier")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = nil)
  if valid_602537 != nil:
    section.add "DBClusterIdentifier", valid_602537
  var valid_602538 = formData.getOrDefault("EngineVersion")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "EngineVersion", valid_602538
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602539: Call_PostRestoreDBClusterFromSnapshot_602515;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_602539.validator(path, query, header, formData, body)
  let scheme = call_602539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602539.url(scheme.get, call_602539.host, call_602539.base,
                         call_602539.route, valid.getOrDefault("path"))
  result = hook(call_602539, url, valid)

proc call*(call_602540: Call_PostRestoreDBClusterFromSnapshot_602515;
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
  var query_602541 = newJObject()
  var formData_602542 = newJObject()
  add(formData_602542, "Port", newJInt(Port))
  add(formData_602542, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_602542.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_602542.add "Tags", Tags
  add(formData_602542, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_602542, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602541, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_602542.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_602542.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_602542, "KmsKeyId", newJString(KmsKeyId))
  add(formData_602542, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_602542, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_602542, "EngineVersion", newJString(EngineVersion))
  add(query_602541, "Version", newJString(Version))
  result = call_602540.call(nil, query_602541, nil, formData_602542, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_602515(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_602516, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_602517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_602488 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBClusterFromSnapshot_602490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterFromSnapshot_602489(path: JsonNode;
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
  var valid_602491 = query.getOrDefault("Engine")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = nil)
  if valid_602491 != nil:
    section.add "Engine", valid_602491
  var valid_602492 = query.getOrDefault("AvailabilityZones")
  valid_602492 = validateParameter(valid_602492, JArray, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "AvailabilityZones", valid_602492
  var valid_602493 = query.getOrDefault("DBClusterIdentifier")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = nil)
  if valid_602493 != nil:
    section.add "DBClusterIdentifier", valid_602493
  var valid_602494 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602494 = validateParameter(valid_602494, JArray, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "VpcSecurityGroupIds", valid_602494
  var valid_602495 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_602495 = validateParameter(valid_602495, JArray, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602495
  var valid_602496 = query.getOrDefault("Tags")
  valid_602496 = validateParameter(valid_602496, JArray, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "Tags", valid_602496
  var valid_602497 = query.getOrDefault("DeletionProtection")
  valid_602497 = validateParameter(valid_602497, JBool, required = false, default = nil)
  if valid_602497 != nil:
    section.add "DeletionProtection", valid_602497
  var valid_602498 = query.getOrDefault("Action")
  valid_602498 = validateParameter(valid_602498, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_602498 != nil:
    section.add "Action", valid_602498
  var valid_602499 = query.getOrDefault("DBSubnetGroupName")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "DBSubnetGroupName", valid_602499
  var valid_602500 = query.getOrDefault("KmsKeyId")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "KmsKeyId", valid_602500
  var valid_602501 = query.getOrDefault("EngineVersion")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "EngineVersion", valid_602501
  var valid_602502 = query.getOrDefault("Port")
  valid_602502 = validateParameter(valid_602502, JInt, required = false, default = nil)
  if valid_602502 != nil:
    section.add "Port", valid_602502
  var valid_602503 = query.getOrDefault("SnapshotIdentifier")
  valid_602503 = validateParameter(valid_602503, JString, required = true,
                                 default = nil)
  if valid_602503 != nil:
    section.add "SnapshotIdentifier", valid_602503
  var valid_602504 = query.getOrDefault("Version")
  valid_602504 = validateParameter(valid_602504, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602504 != nil:
    section.add "Version", valid_602504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602505 = header.getOrDefault("X-Amz-Date")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Date", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Security-Token")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Security-Token", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Content-Sha256", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Algorithm")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Algorithm", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Signature")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Signature", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-SignedHeaders", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Credential")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Credential", valid_602511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602512: Call_GetRestoreDBClusterFromSnapshot_602488;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_602512.validator(path, query, header, formData, body)
  let scheme = call_602512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602512.url(scheme.get, call_602512.host, call_602512.base,
                         call_602512.route, valid.getOrDefault("path"))
  result = hook(call_602512, url, valid)

proc call*(call_602513: Call_GetRestoreDBClusterFromSnapshot_602488;
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
  var query_602514 = newJObject()
  add(query_602514, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_602514.add "AvailabilityZones", AvailabilityZones
  add(query_602514, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_602514.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_602514.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_602514.add "Tags", Tags
  add(query_602514, "DeletionProtection", newJBool(DeletionProtection))
  add(query_602514, "Action", newJString(Action))
  add(query_602514, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602514, "KmsKeyId", newJString(KmsKeyId))
  add(query_602514, "EngineVersion", newJString(EngineVersion))
  add(query_602514, "Port", newJInt(Port))
  add(query_602514, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_602514, "Version", newJString(Version))
  result = call_602513.call(nil, query_602514, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_602488(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_602489, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_602490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_602569 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBClusterToPointInTime_602571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterToPointInTime_602570(path: JsonNode;
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
  var valid_602572 = query.getOrDefault("Action")
  valid_602572 = validateParameter(valid_602572, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_602572 != nil:
    section.add "Action", valid_602572
  var valid_602573 = query.getOrDefault("Version")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602573 != nil:
    section.add "Version", valid_602573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602574 = header.getOrDefault("X-Amz-Date")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Date", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Security-Token")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Security-Token", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Content-Sha256", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Algorithm")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Algorithm", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Signature")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Signature", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-SignedHeaders", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
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
  var valid_602581 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = nil)
  if valid_602581 != nil:
    section.add "SourceDBClusterIdentifier", valid_602581
  var valid_602582 = formData.getOrDefault("UseLatestRestorableTime")
  valid_602582 = validateParameter(valid_602582, JBool, required = false, default = nil)
  if valid_602582 != nil:
    section.add "UseLatestRestorableTime", valid_602582
  var valid_602583 = formData.getOrDefault("Port")
  valid_602583 = validateParameter(valid_602583, JInt, required = false, default = nil)
  if valid_602583 != nil:
    section.add "Port", valid_602583
  var valid_602584 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602584 = validateParameter(valid_602584, JArray, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "VpcSecurityGroupIds", valid_602584
  var valid_602585 = formData.getOrDefault("RestoreToTime")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "RestoreToTime", valid_602585
  var valid_602586 = formData.getOrDefault("Tags")
  valid_602586 = validateParameter(valid_602586, JArray, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "Tags", valid_602586
  var valid_602587 = formData.getOrDefault("DeletionProtection")
  valid_602587 = validateParameter(valid_602587, JBool, required = false, default = nil)
  if valid_602587 != nil:
    section.add "DeletionProtection", valid_602587
  var valid_602588 = formData.getOrDefault("DBSubnetGroupName")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "DBSubnetGroupName", valid_602588
  var valid_602589 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_602589 = validateParameter(valid_602589, JArray, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602589
  var valid_602590 = formData.getOrDefault("KmsKeyId")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "KmsKeyId", valid_602590
  var valid_602591 = formData.getOrDefault("DBClusterIdentifier")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = nil)
  if valid_602591 != nil:
    section.add "DBClusterIdentifier", valid_602591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602592: Call_PostRestoreDBClusterToPointInTime_602569;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_602592.validator(path, query, header, formData, body)
  let scheme = call_602592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602592.url(scheme.get, call_602592.host, call_602592.base,
                         call_602592.route, valid.getOrDefault("path"))
  result = hook(call_602592, url, valid)

proc call*(call_602593: Call_PostRestoreDBClusterToPointInTime_602569;
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
  var query_602594 = newJObject()
  var formData_602595 = newJObject()
  add(formData_602595, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_602595, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_602595, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_602595.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602595, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_602595.add "Tags", Tags
  add(formData_602595, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_602595, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602594, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_602595.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_602595, "KmsKeyId", newJString(KmsKeyId))
  add(formData_602595, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602594, "Version", newJString(Version))
  result = call_602593.call(nil, query_602594, nil, formData_602595, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_602569(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_602570, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_602571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_602543 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBClusterToPointInTime_602545(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterToPointInTime_602544(path: JsonNode;
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
  var valid_602546 = query.getOrDefault("RestoreToTime")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "RestoreToTime", valid_602546
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602547 = query.getOrDefault("DBClusterIdentifier")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = nil)
  if valid_602547 != nil:
    section.add "DBClusterIdentifier", valid_602547
  var valid_602548 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602548 = validateParameter(valid_602548, JArray, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "VpcSecurityGroupIds", valid_602548
  var valid_602549 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_602549 = validateParameter(valid_602549, JArray, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602549
  var valid_602550 = query.getOrDefault("Tags")
  valid_602550 = validateParameter(valid_602550, JArray, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "Tags", valid_602550
  var valid_602551 = query.getOrDefault("DeletionProtection")
  valid_602551 = validateParameter(valid_602551, JBool, required = false, default = nil)
  if valid_602551 != nil:
    section.add "DeletionProtection", valid_602551
  var valid_602552 = query.getOrDefault("UseLatestRestorableTime")
  valid_602552 = validateParameter(valid_602552, JBool, required = false, default = nil)
  if valid_602552 != nil:
    section.add "UseLatestRestorableTime", valid_602552
  var valid_602553 = query.getOrDefault("Action")
  valid_602553 = validateParameter(valid_602553, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_602553 != nil:
    section.add "Action", valid_602553
  var valid_602554 = query.getOrDefault("DBSubnetGroupName")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "DBSubnetGroupName", valid_602554
  var valid_602555 = query.getOrDefault("KmsKeyId")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "KmsKeyId", valid_602555
  var valid_602556 = query.getOrDefault("Port")
  valid_602556 = validateParameter(valid_602556, JInt, required = false, default = nil)
  if valid_602556 != nil:
    section.add "Port", valid_602556
  var valid_602557 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_602557 = validateParameter(valid_602557, JString, required = true,
                                 default = nil)
  if valid_602557 != nil:
    section.add "SourceDBClusterIdentifier", valid_602557
  var valid_602558 = query.getOrDefault("Version")
  valid_602558 = validateParameter(valid_602558, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602558 != nil:
    section.add "Version", valid_602558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602559 = header.getOrDefault("X-Amz-Date")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Date", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Content-Sha256", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Algorithm")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Algorithm", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Signature")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Signature", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-SignedHeaders", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602566: Call_GetRestoreDBClusterToPointInTime_602543;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_602566.validator(path, query, header, formData, body)
  let scheme = call_602566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602566.url(scheme.get, call_602566.host, call_602566.base,
                         call_602566.route, valid.getOrDefault("path"))
  result = hook(call_602566, url, valid)

proc call*(call_602567: Call_GetRestoreDBClusterToPointInTime_602543;
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
  var query_602568 = newJObject()
  add(query_602568, "RestoreToTime", newJString(RestoreToTime))
  add(query_602568, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_602568.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_602568.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_602568.add "Tags", Tags
  add(query_602568, "DeletionProtection", newJBool(DeletionProtection))
  add(query_602568, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_602568, "Action", newJString(Action))
  add(query_602568, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602568, "KmsKeyId", newJString(KmsKeyId))
  add(query_602568, "Port", newJInt(Port))
  add(query_602568, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_602568, "Version", newJString(Version))
  result = call_602567.call(nil, query_602568, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_602543(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_602544, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_602545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_602612 = ref object of OpenApiRestCall_600410
proc url_PostStartDBCluster_602614(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStartDBCluster_602613(path: JsonNode; query: JsonNode;
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
  var valid_602615 = query.getOrDefault("Action")
  valid_602615 = validateParameter(valid_602615, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_602615 != nil:
    section.add "Action", valid_602615
  var valid_602616 = query.getOrDefault("Version")
  valid_602616 = validateParameter(valid_602616, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602616 != nil:
    section.add "Version", valid_602616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602617 = header.getOrDefault("X-Amz-Date")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Date", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Security-Token")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Security-Token", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Content-Sha256", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Algorithm")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Algorithm", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Signature")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Signature", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-SignedHeaders", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Credential")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Credential", valid_602623
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602624 = formData.getOrDefault("DBClusterIdentifier")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = nil)
  if valid_602624 != nil:
    section.add "DBClusterIdentifier", valid_602624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602625: Call_PostStartDBCluster_602612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_602625.validator(path, query, header, formData, body)
  let scheme = call_602625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602625.url(scheme.get, call_602625.host, call_602625.base,
                         call_602625.route, valid.getOrDefault("path"))
  result = hook(call_602625, url, valid)

proc call*(call_602626: Call_PostStartDBCluster_602612;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_602627 = newJObject()
  var formData_602628 = newJObject()
  add(query_602627, "Action", newJString(Action))
  add(formData_602628, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602627, "Version", newJString(Version))
  result = call_602626.call(nil, query_602627, nil, formData_602628, nil)

var postStartDBCluster* = Call_PostStartDBCluster_602612(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_602613, base: "/",
    url: url_PostStartDBCluster_602614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_602596 = ref object of OpenApiRestCall_600410
proc url_GetStartDBCluster_602598(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStartDBCluster_602597(path: JsonNode; query: JsonNode;
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
  var valid_602599 = query.getOrDefault("DBClusterIdentifier")
  valid_602599 = validateParameter(valid_602599, JString, required = true,
                                 default = nil)
  if valid_602599 != nil:
    section.add "DBClusterIdentifier", valid_602599
  var valid_602600 = query.getOrDefault("Action")
  valid_602600 = validateParameter(valid_602600, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_602600 != nil:
    section.add "Action", valid_602600
  var valid_602601 = query.getOrDefault("Version")
  valid_602601 = validateParameter(valid_602601, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602601 != nil:
    section.add "Version", valid_602601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602602 = header.getOrDefault("X-Amz-Date")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Date", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Security-Token")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Security-Token", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Content-Sha256", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Algorithm")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Algorithm", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Signature")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Signature", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-SignedHeaders", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Credential")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Credential", valid_602608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602609: Call_GetStartDBCluster_602596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_602609.validator(path, query, header, formData, body)
  let scheme = call_602609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602609.url(scheme.get, call_602609.host, call_602609.base,
                         call_602609.route, valid.getOrDefault("path"))
  result = hook(call_602609, url, valid)

proc call*(call_602610: Call_GetStartDBCluster_602596; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602611 = newJObject()
  add(query_602611, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602611, "Action", newJString(Action))
  add(query_602611, "Version", newJString(Version))
  result = call_602610.call(nil, query_602611, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_602596(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_602597,
    base: "/", url: url_GetStartDBCluster_602598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_602645 = ref object of OpenApiRestCall_600410
proc url_PostStopDBCluster_602647(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStopDBCluster_602646(path: JsonNode; query: JsonNode;
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
  var valid_602648 = query.getOrDefault("Action")
  valid_602648 = validateParameter(valid_602648, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_602648 != nil:
    section.add "Action", valid_602648
  var valid_602649 = query.getOrDefault("Version")
  valid_602649 = validateParameter(valid_602649, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602649 != nil:
    section.add "Version", valid_602649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602650 = header.getOrDefault("X-Amz-Date")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Date", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Security-Token")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Security-Token", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Content-Sha256", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Algorithm")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Algorithm", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Signature")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Signature", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-SignedHeaders", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Credential")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Credential", valid_602656
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602657 = formData.getOrDefault("DBClusterIdentifier")
  valid_602657 = validateParameter(valid_602657, JString, required = true,
                                 default = nil)
  if valid_602657 != nil:
    section.add "DBClusterIdentifier", valid_602657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602658: Call_PostStopDBCluster_602645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_602658.validator(path, query, header, formData, body)
  let scheme = call_602658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602658.url(scheme.get, call_602658.host, call_602658.base,
                         call_602658.route, valid.getOrDefault("path"))
  result = hook(call_602658, url, valid)

proc call*(call_602659: Call_PostStopDBCluster_602645; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_602660 = newJObject()
  var formData_602661 = newJObject()
  add(query_602660, "Action", newJString(Action))
  add(formData_602661, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602660, "Version", newJString(Version))
  result = call_602659.call(nil, query_602660, nil, formData_602661, nil)

var postStopDBCluster* = Call_PostStopDBCluster_602645(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_602646,
    base: "/", url: url_PostStopDBCluster_602647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_602629 = ref object of OpenApiRestCall_600410
proc url_GetStopDBCluster_602631(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStopDBCluster_602630(path: JsonNode; query: JsonNode;
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
  var valid_602632 = query.getOrDefault("DBClusterIdentifier")
  valid_602632 = validateParameter(valid_602632, JString, required = true,
                                 default = nil)
  if valid_602632 != nil:
    section.add "DBClusterIdentifier", valid_602632
  var valid_602633 = query.getOrDefault("Action")
  valid_602633 = validateParameter(valid_602633, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_602633 != nil:
    section.add "Action", valid_602633
  var valid_602634 = query.getOrDefault("Version")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602634 != nil:
    section.add "Version", valid_602634
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602635 = header.getOrDefault("X-Amz-Date")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Date", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Security-Token")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Security-Token", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Content-Sha256", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Algorithm")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Algorithm", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-SignedHeaders", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Credential")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Credential", valid_602641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602642: Call_GetStopDBCluster_602629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_602642.validator(path, query, header, formData, body)
  let scheme = call_602642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602642.url(scheme.get, call_602642.host, call_602642.base,
                         call_602642.route, valid.getOrDefault("path"))
  result = hook(call_602642, url, valid)

proc call*(call_602643: Call_GetStopDBCluster_602629; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602644 = newJObject()
  add(query_602644, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602644, "Action", newJString(Action))
  add(query_602644, "Version", newJString(Version))
  result = call_602643.call(nil, query_602644, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_602629(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_602630,
    base: "/", url: url_GetStopDBCluster_602631,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
