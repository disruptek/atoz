
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_603059 = ref object of OpenApiRestCall_602450
proc url_PostAddTagsToResource_603061(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_603060(path: JsonNode; query: JsonNode;
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
  var valid_603062 = query.getOrDefault("Action")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603062 != nil:
    section.add "Action", valid_603062
  var valid_603063 = query.getOrDefault("Version")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603063 != nil:
    section.add "Version", valid_603063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603064 = header.getOrDefault("X-Amz-Date")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Date", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Security-Token")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Security-Token", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Content-Sha256", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Algorithm")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Algorithm", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Signature")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Signature", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-SignedHeaders", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Credential")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Credential", valid_603070
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603071 = formData.getOrDefault("Tags")
  valid_603071 = validateParameter(valid_603071, JArray, required = true, default = nil)
  if valid_603071 != nil:
    section.add "Tags", valid_603071
  var valid_603072 = formData.getOrDefault("ResourceName")
  valid_603072 = validateParameter(valid_603072, JString, required = true,
                                 default = nil)
  if valid_603072 != nil:
    section.add "ResourceName", valid_603072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603073: Call_PostAddTagsToResource_603059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_603073.validator(path, query, header, formData, body)
  let scheme = call_603073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603073.url(scheme.get, call_603073.host, call_603073.base,
                         call_603073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603073, url, valid)

proc call*(call_603074: Call_PostAddTagsToResource_603059; Tags: JsonNode;
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
  var query_603075 = newJObject()
  var formData_603076 = newJObject()
  if Tags != nil:
    formData_603076.add "Tags", Tags
  add(query_603075, "Action", newJString(Action))
  add(formData_603076, "ResourceName", newJString(ResourceName))
  add(query_603075, "Version", newJString(Version))
  result = call_603074.call(nil, query_603075, nil, formData_603076, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_603059(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_603060, base: "/",
    url: url_PostAddTagsToResource_603061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_602787 = ref object of OpenApiRestCall_602450
proc url_GetAddTagsToResource_602789(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_602788(path: JsonNode; query: JsonNode;
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
  var valid_602901 = query.getOrDefault("Tags")
  valid_602901 = validateParameter(valid_602901, JArray, required = true, default = nil)
  if valid_602901 != nil:
    section.add "Tags", valid_602901
  var valid_602902 = query.getOrDefault("ResourceName")
  valid_602902 = validateParameter(valid_602902, JString, required = true,
                                 default = nil)
  if valid_602902 != nil:
    section.add "ResourceName", valid_602902
  var valid_602916 = query.getOrDefault("Action")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_602916 != nil:
    section.add "Action", valid_602916
  var valid_602917 = query.getOrDefault("Version")
  valid_602917 = validateParameter(valid_602917, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602917 != nil:
    section.add "Version", valid_602917
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Security-Token")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Security-Token", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Content-Sha256", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Algorithm")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Algorithm", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Signature")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Signature", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-SignedHeaders", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Credential")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Credential", valid_602924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602947: Call_GetAddTagsToResource_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_602947.validator(path, query, header, formData, body)
  let scheme = call_602947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602947.url(scheme.get, call_602947.host, call_602947.base,
                         call_602947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602947, url, valid)

proc call*(call_603018: Call_GetAddTagsToResource_602787; Tags: JsonNode;
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
  var query_603019 = newJObject()
  if Tags != nil:
    query_603019.add "Tags", Tags
  add(query_603019, "ResourceName", newJString(ResourceName))
  add(query_603019, "Action", newJString(Action))
  add(query_603019, "Version", newJString(Version))
  result = call_603018.call(nil, query_603019, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_602787(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_602788, base: "/",
    url: url_GetAddTagsToResource_602789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_603095 = ref object of OpenApiRestCall_602450
proc url_PostApplyPendingMaintenanceAction_603097(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_603096(path: JsonNode;
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
  var valid_603098 = query.getOrDefault("Action")
  valid_603098 = validateParameter(valid_603098, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_603098 != nil:
    section.add "Action", valid_603098
  var valid_603099 = query.getOrDefault("Version")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603099 != nil:
    section.add "Version", valid_603099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
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
  var valid_603107 = formData.getOrDefault("ApplyAction")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "ApplyAction", valid_603107
  var valid_603108 = formData.getOrDefault("ResourceIdentifier")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "ResourceIdentifier", valid_603108
  var valid_603109 = formData.getOrDefault("OptInType")
  valid_603109 = validateParameter(valid_603109, JString, required = true,
                                 default = nil)
  if valid_603109 != nil:
    section.add "OptInType", valid_603109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_PostApplyPendingMaintenanceAction_603095;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_PostApplyPendingMaintenanceAction_603095;
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
  var query_603112 = newJObject()
  var formData_603113 = newJObject()
  add(query_603112, "Action", newJString(Action))
  add(formData_603113, "ApplyAction", newJString(ApplyAction))
  add(formData_603113, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_603113, "OptInType", newJString(OptInType))
  add(query_603112, "Version", newJString(Version))
  result = call_603111.call(nil, query_603112, nil, formData_603113, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_603095(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_603096, base: "/",
    url: url_PostApplyPendingMaintenanceAction_603097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_603077 = ref object of OpenApiRestCall_602450
proc url_GetApplyPendingMaintenanceAction_603079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_603078(path: JsonNode;
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
  var valid_603080 = query.getOrDefault("ApplyAction")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = nil)
  if valid_603080 != nil:
    section.add "ApplyAction", valid_603080
  var valid_603081 = query.getOrDefault("ResourceIdentifier")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "ResourceIdentifier", valid_603081
  var valid_603082 = query.getOrDefault("Action")
  valid_603082 = validateParameter(valid_603082, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_603082 != nil:
    section.add "Action", valid_603082
  var valid_603083 = query.getOrDefault("OptInType")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = nil)
  if valid_603083 != nil:
    section.add "OptInType", valid_603083
  var valid_603084 = query.getOrDefault("Version")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603084 != nil:
    section.add "Version", valid_603084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Security-Token")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Security-Token", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Signature")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Signature", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-SignedHeaders", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Credential")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Credential", valid_603091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603092: Call_GetApplyPendingMaintenanceAction_603077;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_603092.validator(path, query, header, formData, body)
  let scheme = call_603092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603092.url(scheme.get, call_603092.host, call_603092.base,
                         call_603092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603092, url, valid)

proc call*(call_603093: Call_GetApplyPendingMaintenanceAction_603077;
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
  var query_603094 = newJObject()
  add(query_603094, "ApplyAction", newJString(ApplyAction))
  add(query_603094, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_603094, "Action", newJString(Action))
  add(query_603094, "OptInType", newJString(OptInType))
  add(query_603094, "Version", newJString(Version))
  result = call_603093.call(nil, query_603094, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_603077(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_603078, base: "/",
    url: url_GetApplyPendingMaintenanceAction_603079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_603133 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBClusterParameterGroup_603135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_603134(path: JsonNode;
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
  var valid_603136 = query.getOrDefault("Action")
  valid_603136 = validateParameter(valid_603136, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_603136 != nil:
    section.add "Action", valid_603136
  var valid_603137 = query.getOrDefault("Version")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603137 != nil:
    section.add "Version", valid_603137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Security-Token")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Security-Token", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Content-Sha256", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Signature")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Signature", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-SignedHeaders", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Credential")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Credential", valid_603144
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
  var valid_603145 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = nil)
  if valid_603145 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_603145
  var valid_603146 = formData.getOrDefault("Tags")
  valid_603146 = validateParameter(valid_603146, JArray, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "Tags", valid_603146
  var valid_603147 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_603147
  var valid_603148 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_603148
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_PostCopyDBClusterParameterGroup_603133;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_PostCopyDBClusterParameterGroup_603133;
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
  var query_603151 = newJObject()
  var formData_603152 = newJObject()
  add(formData_603152, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_603152.add "Tags", Tags
  add(query_603151, "Action", newJString(Action))
  add(formData_603152, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_603152, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_603151, "Version", newJString(Version))
  result = call_603150.call(nil, query_603151, nil, formData_603152, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_603133(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_603134, base: "/",
    url: url_PostCopyDBClusterParameterGroup_603135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_603114 = ref object of OpenApiRestCall_602450
proc url_GetCopyDBClusterParameterGroup_603116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_603115(path: JsonNode;
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
  var valid_603117 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_603117
  var valid_603118 = query.getOrDefault("Tags")
  valid_603118 = validateParameter(valid_603118, JArray, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "Tags", valid_603118
  var valid_603119 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = nil)
  if valid_603119 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_603119
  var valid_603120 = query.getOrDefault("Action")
  valid_603120 = validateParameter(valid_603120, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_603120 != nil:
    section.add "Action", valid_603120
  var valid_603121 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_603121
  var valid_603122 = query.getOrDefault("Version")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603122 != nil:
    section.add "Version", valid_603122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603123 = header.getOrDefault("X-Amz-Date")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Date", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Security-Token")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Security-Token", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Content-Sha256", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Algorithm")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Algorithm", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Signature")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Signature", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-SignedHeaders", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Credential")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Credential", valid_603129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_GetCopyDBClusterParameterGroup_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_GetCopyDBClusterParameterGroup_603114;
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
  var query_603132 = newJObject()
  add(query_603132, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_603132.add "Tags", Tags
  add(query_603132, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_603132, "Action", newJString(Action))
  add(query_603132, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_603132, "Version", newJString(Version))
  result = call_603131.call(nil, query_603132, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_603114(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_603115, base: "/",
    url: url_GetCopyDBClusterParameterGroup_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_603174 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBClusterSnapshot_603176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterSnapshot_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = query.getOrDefault("Action")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_603177 != nil:
    section.add "Action", valid_603177
  var valid_603178 = query.getOrDefault("Version")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603178 != nil:
    section.add "Version", valid_603178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603179 = header.getOrDefault("X-Amz-Date")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Date", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Security-Token")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Security-Token", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Content-Sha256", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Algorithm")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Algorithm", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-SignedHeaders", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Credential")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Credential", valid_603185
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
  var valid_603186 = formData.getOrDefault("PreSignedUrl")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "PreSignedUrl", valid_603186
  var valid_603187 = formData.getOrDefault("Tags")
  valid_603187 = validateParameter(valid_603187, JArray, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "Tags", valid_603187
  var valid_603188 = formData.getOrDefault("CopyTags")
  valid_603188 = validateParameter(valid_603188, JBool, required = false, default = nil)
  if valid_603188 != nil:
    section.add "CopyTags", valid_603188
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_603189 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_603189
  var valid_603190 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_603190
  var valid_603191 = formData.getOrDefault("KmsKeyId")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "KmsKeyId", valid_603191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_PostCopyDBClusterSnapshot_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_PostCopyDBClusterSnapshot_603174;
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
  var query_603194 = newJObject()
  var formData_603195 = newJObject()
  add(formData_603195, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_603195.add "Tags", Tags
  add(formData_603195, "CopyTags", newJBool(CopyTags))
  add(formData_603195, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_603195, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_603194, "Action", newJString(Action))
  add(formData_603195, "KmsKeyId", newJString(KmsKeyId))
  add(query_603194, "Version", newJString(Version))
  result = call_603193.call(nil, query_603194, nil, formData_603195, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_603174(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_603175, base: "/",
    url: url_PostCopyDBClusterSnapshot_603176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_603153 = ref object of OpenApiRestCall_602450
proc url_GetCopyDBClusterSnapshot_603155(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterSnapshot_603154(path: JsonNode; query: JsonNode;
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
  var valid_603156 = query.getOrDefault("PreSignedUrl")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "PreSignedUrl", valid_603156
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_603157 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_603157
  var valid_603158 = query.getOrDefault("Tags")
  valid_603158 = validateParameter(valid_603158, JArray, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "Tags", valid_603158
  var valid_603159 = query.getOrDefault("Action")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_603159 != nil:
    section.add "Action", valid_603159
  var valid_603160 = query.getOrDefault("KmsKeyId")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "KmsKeyId", valid_603160
  var valid_603161 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_603161
  var valid_603162 = query.getOrDefault("Version")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603162 != nil:
    section.add "Version", valid_603162
  var valid_603163 = query.getOrDefault("CopyTags")
  valid_603163 = validateParameter(valid_603163, JBool, required = false, default = nil)
  if valid_603163 != nil:
    section.add "CopyTags", valid_603163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603164 = header.getOrDefault("X-Amz-Date")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Date", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Security-Token")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Security-Token", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Content-Sha256", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Algorithm")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Algorithm", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-SignedHeaders", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Credential")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Credential", valid_603170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_GetCopyDBClusterSnapshot_603153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_GetCopyDBClusterSnapshot_603153;
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
  var query_603173 = newJObject()
  add(query_603173, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_603173, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_603173.add "Tags", Tags
  add(query_603173, "Action", newJString(Action))
  add(query_603173, "KmsKeyId", newJString(KmsKeyId))
  add(query_603173, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_603173, "Version", newJString(Version))
  add(query_603173, "CopyTags", newJBool(CopyTags))
  result = call_603172.call(nil, query_603173, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_603153(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_603154, base: "/",
    url: url_GetCopyDBClusterSnapshot_603155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_603229 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBCluster_603231(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBCluster_603230(path: JsonNode; query: JsonNode;
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
  var valid_603232 = query.getOrDefault("Action")
  valid_603232 = validateParameter(valid_603232, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_603232 != nil:
    section.add "Action", valid_603232
  var valid_603233 = query.getOrDefault("Version")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603233 != nil:
    section.add "Version", valid_603233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603234 = header.getOrDefault("X-Amz-Date")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Date", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Security-Token")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Security-Token", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Content-Sha256", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Algorithm")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Algorithm", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-SignedHeaders", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
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
  var valid_603241 = formData.getOrDefault("Port")
  valid_603241 = validateParameter(valid_603241, JInt, required = false, default = nil)
  if valid_603241 != nil:
    section.add "Port", valid_603241
  var valid_603242 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603242 = validateParameter(valid_603242, JArray, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "VpcSecurityGroupIds", valid_603242
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603243 = formData.getOrDefault("Engine")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = nil)
  if valid_603243 != nil:
    section.add "Engine", valid_603243
  var valid_603244 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603244 = validateParameter(valid_603244, JInt, required = false, default = nil)
  if valid_603244 != nil:
    section.add "BackupRetentionPeriod", valid_603244
  var valid_603245 = formData.getOrDefault("Tags")
  valid_603245 = validateParameter(valid_603245, JArray, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "Tags", valid_603245
  var valid_603246 = formData.getOrDefault("MasterUserPassword")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = nil)
  if valid_603246 != nil:
    section.add "MasterUserPassword", valid_603246
  var valid_603247 = formData.getOrDefault("DeletionProtection")
  valid_603247 = validateParameter(valid_603247, JBool, required = false, default = nil)
  if valid_603247 != nil:
    section.add "DeletionProtection", valid_603247
  var valid_603248 = formData.getOrDefault("DBSubnetGroupName")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "DBSubnetGroupName", valid_603248
  var valid_603249 = formData.getOrDefault("AvailabilityZones")
  valid_603249 = validateParameter(valid_603249, JArray, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "AvailabilityZones", valid_603249
  var valid_603250 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "DBClusterParameterGroupName", valid_603250
  var valid_603251 = formData.getOrDefault("MasterUsername")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "MasterUsername", valid_603251
  var valid_603252 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_603252 = validateParameter(valid_603252, JArray, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603252
  var valid_603253 = formData.getOrDefault("PreferredBackupWindow")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "PreferredBackupWindow", valid_603253
  var valid_603254 = formData.getOrDefault("KmsKeyId")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "KmsKeyId", valid_603254
  var valid_603255 = formData.getOrDefault("StorageEncrypted")
  valid_603255 = validateParameter(valid_603255, JBool, required = false, default = nil)
  if valid_603255 != nil:
    section.add "StorageEncrypted", valid_603255
  var valid_603256 = formData.getOrDefault("DBClusterIdentifier")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = nil)
  if valid_603256 != nil:
    section.add "DBClusterIdentifier", valid_603256
  var valid_603257 = formData.getOrDefault("EngineVersion")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "EngineVersion", valid_603257
  var valid_603258 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "PreferredMaintenanceWindow", valid_603258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_PostCreateDBCluster_603229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_PostCreateDBCluster_603229; Engine: string;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
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
  var query_603261 = newJObject()
  var formData_603262 = newJObject()
  add(formData_603262, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_603262.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603262, "Engine", newJString(Engine))
  add(formData_603262, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_603262.add "Tags", Tags
  add(formData_603262, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603262, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_603262, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603261, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_603262.add "AvailabilityZones", AvailabilityZones
  add(formData_603262, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_603262, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_603262.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_603262, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603262, "KmsKeyId", newJString(KmsKeyId))
  add(formData_603262, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_603262, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_603262, "EngineVersion", newJString(EngineVersion))
  add(query_603261, "Version", newJString(Version))
  add(formData_603262, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603260.call(nil, query_603261, nil, formData_603262, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_603229(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_603230, base: "/",
    url: url_PostCreateDBCluster_603231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_603196 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBCluster_603198(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBCluster_603197(path: JsonNode; query: JsonNode;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603199 = query.getOrDefault("Engine")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = nil)
  if valid_603199 != nil:
    section.add "Engine", valid_603199
  var valid_603200 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "PreferredMaintenanceWindow", valid_603200
  var valid_603201 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "DBClusterParameterGroupName", valid_603201
  var valid_603202 = query.getOrDefault("StorageEncrypted")
  valid_603202 = validateParameter(valid_603202, JBool, required = false, default = nil)
  if valid_603202 != nil:
    section.add "StorageEncrypted", valid_603202
  var valid_603203 = query.getOrDefault("AvailabilityZones")
  valid_603203 = validateParameter(valid_603203, JArray, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "AvailabilityZones", valid_603203
  var valid_603204 = query.getOrDefault("DBClusterIdentifier")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "DBClusterIdentifier", valid_603204
  var valid_603205 = query.getOrDefault("MasterUserPassword")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "MasterUserPassword", valid_603205
  var valid_603206 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603206 = validateParameter(valid_603206, JArray, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "VpcSecurityGroupIds", valid_603206
  var valid_603207 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_603207 = validateParameter(valid_603207, JArray, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603207
  var valid_603208 = query.getOrDefault("Tags")
  valid_603208 = validateParameter(valid_603208, JArray, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Tags", valid_603208
  var valid_603209 = query.getOrDefault("BackupRetentionPeriod")
  valid_603209 = validateParameter(valid_603209, JInt, required = false, default = nil)
  if valid_603209 != nil:
    section.add "BackupRetentionPeriod", valid_603209
  var valid_603210 = query.getOrDefault("DeletionProtection")
  valid_603210 = validateParameter(valid_603210, JBool, required = false, default = nil)
  if valid_603210 != nil:
    section.add "DeletionProtection", valid_603210
  var valid_603211 = query.getOrDefault("Action")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_603211 != nil:
    section.add "Action", valid_603211
  var valid_603212 = query.getOrDefault("DBSubnetGroupName")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "DBSubnetGroupName", valid_603212
  var valid_603213 = query.getOrDefault("KmsKeyId")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "KmsKeyId", valid_603213
  var valid_603214 = query.getOrDefault("EngineVersion")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "EngineVersion", valid_603214
  var valid_603215 = query.getOrDefault("Port")
  valid_603215 = validateParameter(valid_603215, JInt, required = false, default = nil)
  if valid_603215 != nil:
    section.add "Port", valid_603215
  var valid_603216 = query.getOrDefault("PreferredBackupWindow")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "PreferredBackupWindow", valid_603216
  var valid_603217 = query.getOrDefault("Version")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603217 != nil:
    section.add "Version", valid_603217
  var valid_603218 = query.getOrDefault("MasterUsername")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "MasterUsername", valid_603218
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603219 = header.getOrDefault("X-Amz-Date")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Date", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Content-Sha256", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Algorithm")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Algorithm", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Signature")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Signature", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-SignedHeaders", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Credential")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Credential", valid_603225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_GetCreateDBCluster_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_GetCreateDBCluster_603196; Engine: string;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_603228 = newJObject()
  add(query_603228, "Engine", newJString(Engine))
  add(query_603228, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603228, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603228, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_603228.add "AvailabilityZones", AvailabilityZones
  add(query_603228, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603228, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_603228.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_603228.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_603228.add "Tags", Tags
  add(query_603228, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603228, "DeletionProtection", newJBool(DeletionProtection))
  add(query_603228, "Action", newJString(Action))
  add(query_603228, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603228, "KmsKeyId", newJString(KmsKeyId))
  add(query_603228, "EngineVersion", newJString(EngineVersion))
  add(query_603228, "Port", newJInt(Port))
  add(query_603228, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603228, "Version", newJString(Version))
  add(query_603228, "MasterUsername", newJString(MasterUsername))
  result = call_603227.call(nil, query_603228, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_603196(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_603197,
    base: "/", url: url_GetCreateDBCluster_603198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_603282 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBClusterParameterGroup_603284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_603283(path: JsonNode;
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
  var valid_603285 = query.getOrDefault("Action")
  valid_603285 = validateParameter(valid_603285, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_603285 != nil:
    section.add "Action", valid_603285
  var valid_603286 = query.getOrDefault("Version")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603286 != nil:
    section.add "Version", valid_603286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
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
  var valid_603294 = formData.getOrDefault("Tags")
  valid_603294 = validateParameter(valid_603294, JArray, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Tags", valid_603294
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603295 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603295 = validateParameter(valid_603295, JString, required = true,
                                 default = nil)
  if valid_603295 != nil:
    section.add "DBClusterParameterGroupName", valid_603295
  var valid_603296 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603296 = validateParameter(valid_603296, JString, required = true,
                                 default = nil)
  if valid_603296 != nil:
    section.add "DBParameterGroupFamily", valid_603296
  var valid_603297 = formData.getOrDefault("Description")
  valid_603297 = validateParameter(valid_603297, JString, required = true,
                                 default = nil)
  if valid_603297 != nil:
    section.add "Description", valid_603297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_PostCreateDBClusterParameterGroup_603282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_PostCreateDBClusterParameterGroup_603282;
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
  var query_603300 = newJObject()
  var formData_603301 = newJObject()
  if Tags != nil:
    formData_603301.add "Tags", Tags
  add(query_603300, "Action", newJString(Action))
  add(formData_603301, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_603301, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603300, "Version", newJString(Version))
  add(formData_603301, "Description", newJString(Description))
  result = call_603299.call(nil, query_603300, nil, formData_603301, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_603282(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_603283, base: "/",
    url: url_PostCreateDBClusterParameterGroup_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_603263 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBClusterParameterGroup_603265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_603264(path: JsonNode;
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
  var valid_603266 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "DBClusterParameterGroupName", valid_603266
  var valid_603267 = query.getOrDefault("Description")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "Description", valid_603267
  var valid_603268 = query.getOrDefault("DBParameterGroupFamily")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = nil)
  if valid_603268 != nil:
    section.add "DBParameterGroupFamily", valid_603268
  var valid_603269 = query.getOrDefault("Tags")
  valid_603269 = validateParameter(valid_603269, JArray, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "Tags", valid_603269
  var valid_603270 = query.getOrDefault("Action")
  valid_603270 = validateParameter(valid_603270, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_603270 != nil:
    section.add "Action", valid_603270
  var valid_603271 = query.getOrDefault("Version")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603271 != nil:
    section.add "Version", valid_603271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603272 = header.getOrDefault("X-Amz-Date")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Date", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Security-Token")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Security-Token", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Signature")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Signature", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_GetCreateDBClusterParameterGroup_603263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_GetCreateDBClusterParameterGroup_603263;
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
  var query_603281 = newJObject()
  add(query_603281, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603281, "Description", newJString(Description))
  add(query_603281, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603281.add "Tags", Tags
  add(query_603281, "Action", newJString(Action))
  add(query_603281, "Version", newJString(Version))
  result = call_603280.call(nil, query_603281, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_603263(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_603264, base: "/",
    url: url_GetCreateDBClusterParameterGroup_603265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_603320 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBClusterSnapshot_603322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterSnapshot_603321(path: JsonNode; query: JsonNode;
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
  var valid_603323 = query.getOrDefault("Action")
  valid_603323 = validateParameter(valid_603323, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_603323 != nil:
    section.add "Action", valid_603323
  var valid_603324 = query.getOrDefault("Version")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603324 != nil:
    section.add "Version", valid_603324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603325 = header.getOrDefault("X-Amz-Date")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Date", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Security-Token")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Security-Token", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Content-Sha256", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Algorithm")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Algorithm", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Signature")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Signature", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-SignedHeaders", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Credential")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Credential", valid_603331
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
  var valid_603332 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = nil)
  if valid_603332 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603332
  var valid_603333 = formData.getOrDefault("Tags")
  valid_603333 = validateParameter(valid_603333, JArray, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "Tags", valid_603333
  var valid_603334 = formData.getOrDefault("DBClusterIdentifier")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = nil)
  if valid_603334 != nil:
    section.add "DBClusterIdentifier", valid_603334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603335: Call_PostCreateDBClusterSnapshot_603320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_603335.validator(path, query, header, formData, body)
  let scheme = call_603335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603335.url(scheme.get, call_603335.host, call_603335.base,
                         call_603335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603335, url, valid)

proc call*(call_603336: Call_PostCreateDBClusterSnapshot_603320;
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
  var query_603337 = newJObject()
  var formData_603338 = newJObject()
  add(formData_603338, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_603338.add "Tags", Tags
  add(query_603337, "Action", newJString(Action))
  add(formData_603338, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603337, "Version", newJString(Version))
  result = call_603336.call(nil, query_603337, nil, formData_603338, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_603320(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_603321, base: "/",
    url: url_PostCreateDBClusterSnapshot_603322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_603302 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBClusterSnapshot_603304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterSnapshot_603303(path: JsonNode; query: JsonNode;
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
  var valid_603305 = query.getOrDefault("DBClusterIdentifier")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = nil)
  if valid_603305 != nil:
    section.add "DBClusterIdentifier", valid_603305
  var valid_603306 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603306 = validateParameter(valid_603306, JString, required = true,
                                 default = nil)
  if valid_603306 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603306
  var valid_603307 = query.getOrDefault("Tags")
  valid_603307 = validateParameter(valid_603307, JArray, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "Tags", valid_603307
  var valid_603308 = query.getOrDefault("Action")
  valid_603308 = validateParameter(valid_603308, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_603308 != nil:
    section.add "Action", valid_603308
  var valid_603309 = query.getOrDefault("Version")
  valid_603309 = validateParameter(valid_603309, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603309 != nil:
    section.add "Version", valid_603309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603310 = header.getOrDefault("X-Amz-Date")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Date", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Security-Token")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Security-Token", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Content-Sha256", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Algorithm")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Algorithm", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Signature")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Signature", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-SignedHeaders", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Credential")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Credential", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603317: Call_GetCreateDBClusterSnapshot_603302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_603317.validator(path, query, header, formData, body)
  let scheme = call_603317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603317.url(scheme.get, call_603317.host, call_603317.base,
                         call_603317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603317, url, valid)

proc call*(call_603318: Call_GetCreateDBClusterSnapshot_603302;
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
  var query_603319 = newJObject()
  add(query_603319, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603319, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_603319.add "Tags", Tags
  add(query_603319, "Action", newJString(Action))
  add(query_603319, "Version", newJString(Version))
  result = call_603318.call(nil, query_603319, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_603302(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_603303, base: "/",
    url: url_GetCreateDBClusterSnapshot_603304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603363 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstance_603365(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_603364(path: JsonNode; query: JsonNode;
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
  var valid_603366 = query.getOrDefault("Action")
  valid_603366 = validateParameter(valid_603366, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603366 != nil:
    section.add "Action", valid_603366
  var valid_603367 = query.getOrDefault("Version")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603367 != nil:
    section.add "Version", valid_603367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603368 = header.getOrDefault("X-Amz-Date")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Date", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Security-Token")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Security-Token", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Content-Sha256", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Algorithm")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Algorithm", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Signature")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Signature", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-SignedHeaders", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Credential")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Credential", valid_603374
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
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
  var valid_603375 = formData.getOrDefault("Engine")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = nil)
  if valid_603375 != nil:
    section.add "Engine", valid_603375
  var valid_603376 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603376 = validateParameter(valid_603376, JString, required = true,
                                 default = nil)
  if valid_603376 != nil:
    section.add "DBInstanceIdentifier", valid_603376
  var valid_603377 = formData.getOrDefault("Tags")
  valid_603377 = validateParameter(valid_603377, JArray, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "Tags", valid_603377
  var valid_603378 = formData.getOrDefault("AvailabilityZone")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "AvailabilityZone", valid_603378
  var valid_603379 = formData.getOrDefault("PromotionTier")
  valid_603379 = validateParameter(valid_603379, JInt, required = false, default = nil)
  if valid_603379 != nil:
    section.add "PromotionTier", valid_603379
  var valid_603380 = formData.getOrDefault("DBInstanceClass")
  valid_603380 = validateParameter(valid_603380, JString, required = true,
                                 default = nil)
  if valid_603380 != nil:
    section.add "DBInstanceClass", valid_603380
  var valid_603381 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603381 = validateParameter(valid_603381, JBool, required = false, default = nil)
  if valid_603381 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603381
  var valid_603382 = formData.getOrDefault("DBClusterIdentifier")
  valid_603382 = validateParameter(valid_603382, JString, required = true,
                                 default = nil)
  if valid_603382 != nil:
    section.add "DBClusterIdentifier", valid_603382
  var valid_603383 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "PreferredMaintenanceWindow", valid_603383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_PostCreateDBInstance_603363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_PostCreateDBInstance_603363; Engine: string;
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
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
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
  var query_603386 = newJObject()
  var formData_603387 = newJObject()
  add(formData_603387, "Engine", newJString(Engine))
  add(formData_603387, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603387.add "Tags", Tags
  add(formData_603387, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603386, "Action", newJString(Action))
  add(formData_603387, "PromotionTier", newJInt(PromotionTier))
  add(formData_603387, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603387, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603387, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603386, "Version", newJString(Version))
  add(formData_603387, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603385.call(nil, query_603386, nil, formData_603387, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603363(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603364, base: "/",
    url: url_PostCreateDBInstance_603365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603339 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstance_603341(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_603340(path: JsonNode; query: JsonNode;
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
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
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
  var valid_603342 = query.getOrDefault("Engine")
  valid_603342 = validateParameter(valid_603342, JString, required = true,
                                 default = nil)
  if valid_603342 != nil:
    section.add "Engine", valid_603342
  var valid_603343 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "PreferredMaintenanceWindow", valid_603343
  var valid_603344 = query.getOrDefault("PromotionTier")
  valid_603344 = validateParameter(valid_603344, JInt, required = false, default = nil)
  if valid_603344 != nil:
    section.add "PromotionTier", valid_603344
  var valid_603345 = query.getOrDefault("DBClusterIdentifier")
  valid_603345 = validateParameter(valid_603345, JString, required = true,
                                 default = nil)
  if valid_603345 != nil:
    section.add "DBClusterIdentifier", valid_603345
  var valid_603346 = query.getOrDefault("AvailabilityZone")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "AvailabilityZone", valid_603346
  var valid_603347 = query.getOrDefault("Tags")
  valid_603347 = validateParameter(valid_603347, JArray, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "Tags", valid_603347
  var valid_603348 = query.getOrDefault("DBInstanceClass")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "DBInstanceClass", valid_603348
  var valid_603349 = query.getOrDefault("Action")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603349 != nil:
    section.add "Action", valid_603349
  var valid_603350 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603350 = validateParameter(valid_603350, JBool, required = false, default = nil)
  if valid_603350 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603350
  var valid_603351 = query.getOrDefault("Version")
  valid_603351 = validateParameter(valid_603351, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603351 != nil:
    section.add "Version", valid_603351
  var valid_603352 = query.getOrDefault("DBInstanceIdentifier")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "DBInstanceIdentifier", valid_603352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603353 = header.getOrDefault("X-Amz-Date")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Date", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Security-Token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Security-Token", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Content-Sha256", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Algorithm")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Algorithm", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Signature")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Signature", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-SignedHeaders", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Credential")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Credential", valid_603359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603360: Call_GetCreateDBInstance_603339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_603360.validator(path, query, header, formData, body)
  let scheme = call_603360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603360.url(scheme.get, call_603360.host, call_603360.base,
                         call_603360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603360, url, valid)

proc call*(call_603361: Call_GetCreateDBInstance_603339; Engine: string;
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
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_603362 = newJObject()
  add(query_603362, "Engine", newJString(Engine))
  add(query_603362, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603362, "PromotionTier", newJInt(PromotionTier))
  add(query_603362, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603362, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_603362.add "Tags", Tags
  add(query_603362, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603362, "Action", newJString(Action))
  add(query_603362, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603362, "Version", newJString(Version))
  add(query_603362, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603361.call(nil, query_603362, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603339(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603340, base: "/",
    url: url_GetCreateDBInstance_603341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603407 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSubnetGroup_603409(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_603408(path: JsonNode; query: JsonNode;
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
  var valid_603410 = query.getOrDefault("Action")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603410 != nil:
    section.add "Action", valid_603410
  var valid_603411 = query.getOrDefault("Version")
  valid_603411 = validateParameter(valid_603411, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603411 != nil:
    section.add "Version", valid_603411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603412 = header.getOrDefault("X-Amz-Date")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Date", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Security-Token")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Security-Token", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Content-Sha256", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Algorithm")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Algorithm", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Signature")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Signature", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-SignedHeaders", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Credential")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Credential", valid_603418
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
  var valid_603419 = formData.getOrDefault("Tags")
  valid_603419 = validateParameter(valid_603419, JArray, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "Tags", valid_603419
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603420 = formData.getOrDefault("DBSubnetGroupName")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "DBSubnetGroupName", valid_603420
  var valid_603421 = formData.getOrDefault("SubnetIds")
  valid_603421 = validateParameter(valid_603421, JArray, required = true, default = nil)
  if valid_603421 != nil:
    section.add "SubnetIds", valid_603421
  var valid_603422 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = nil)
  if valid_603422 != nil:
    section.add "DBSubnetGroupDescription", valid_603422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603423: Call_PostCreateDBSubnetGroup_603407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603423.validator(path, query, header, formData, body)
  let scheme = call_603423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603423.url(scheme.get, call_603423.host, call_603423.base,
                         call_603423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603423, url, valid)

proc call*(call_603424: Call_PostCreateDBSubnetGroup_603407;
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
  var query_603425 = newJObject()
  var formData_603426 = newJObject()
  if Tags != nil:
    formData_603426.add "Tags", Tags
  add(formData_603426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603426.add "SubnetIds", SubnetIds
  add(query_603425, "Action", newJString(Action))
  add(formData_603426, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603425, "Version", newJString(Version))
  result = call_603424.call(nil, query_603425, nil, formData_603426, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603407(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603408, base: "/",
    url: url_PostCreateDBSubnetGroup_603409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603388 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSubnetGroup_603390(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_603389(path: JsonNode; query: JsonNode;
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
  var valid_603391 = query.getOrDefault("Tags")
  valid_603391 = validateParameter(valid_603391, JArray, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "Tags", valid_603391
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603392 = query.getOrDefault("Action")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603392 != nil:
    section.add "Action", valid_603392
  var valid_603393 = query.getOrDefault("DBSubnetGroupName")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = nil)
  if valid_603393 != nil:
    section.add "DBSubnetGroupName", valid_603393
  var valid_603394 = query.getOrDefault("SubnetIds")
  valid_603394 = validateParameter(valid_603394, JArray, required = true, default = nil)
  if valid_603394 != nil:
    section.add "SubnetIds", valid_603394
  var valid_603395 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "DBSubnetGroupDescription", valid_603395
  var valid_603396 = query.getOrDefault("Version")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603396 != nil:
    section.add "Version", valid_603396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-SignedHeaders", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Credential")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Credential", valid_603403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603404: Call_GetCreateDBSubnetGroup_603388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603404.validator(path, query, header, formData, body)
  let scheme = call_603404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603404.url(scheme.get, call_603404.host, call_603404.base,
                         call_603404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603404, url, valid)

proc call*(call_603405: Call_GetCreateDBSubnetGroup_603388;
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
  var query_603406 = newJObject()
  if Tags != nil:
    query_603406.add "Tags", Tags
  add(query_603406, "Action", newJString(Action))
  add(query_603406, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603406.add "SubnetIds", SubnetIds
  add(query_603406, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603406, "Version", newJString(Version))
  result = call_603405.call(nil, query_603406, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603388(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603389, base: "/",
    url: url_GetCreateDBSubnetGroup_603390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_603445 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBCluster_603447(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBCluster_603446(path: JsonNode; query: JsonNode;
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
  var valid_603448 = query.getOrDefault("Action")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_603448 != nil:
    section.add "Action", valid_603448
  var valid_603449 = query.getOrDefault("Version")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603449 != nil:
    section.add "Version", valid_603449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Content-Sha256", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Algorithm")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Algorithm", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Signature")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Signature", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-SignedHeaders", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Credential")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Credential", valid_603456
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_603457 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603457
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603458 = formData.getOrDefault("DBClusterIdentifier")
  valid_603458 = validateParameter(valid_603458, JString, required = true,
                                 default = nil)
  if valid_603458 != nil:
    section.add "DBClusterIdentifier", valid_603458
  var valid_603459 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603459 = validateParameter(valid_603459, JBool, required = false, default = nil)
  if valid_603459 != nil:
    section.add "SkipFinalSnapshot", valid_603459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_PostDeleteDBCluster_603445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_PostDeleteDBCluster_603445;
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
  var query_603462 = newJObject()
  var formData_603463 = newJObject()
  add(formData_603463, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603462, "Action", newJString(Action))
  add(formData_603463, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603462, "Version", newJString(Version))
  add(formData_603463, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603461.call(nil, query_603462, nil, formData_603463, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_603445(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_603446, base: "/",
    url: url_PostDeleteDBCluster_603447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_603427 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBCluster_603429(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBCluster_603428(path: JsonNode; query: JsonNode;
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
  var valid_603430 = query.getOrDefault("DBClusterIdentifier")
  valid_603430 = validateParameter(valid_603430, JString, required = true,
                                 default = nil)
  if valid_603430 != nil:
    section.add "DBClusterIdentifier", valid_603430
  var valid_603431 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603431
  var valid_603432 = query.getOrDefault("Action")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_603432 != nil:
    section.add "Action", valid_603432
  var valid_603433 = query.getOrDefault("SkipFinalSnapshot")
  valid_603433 = validateParameter(valid_603433, JBool, required = false, default = nil)
  if valid_603433 != nil:
    section.add "SkipFinalSnapshot", valid_603433
  var valid_603434 = query.getOrDefault("Version")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603434 != nil:
    section.add "Version", valid_603434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Content-Sha256", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Algorithm")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Algorithm", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Signature")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Signature", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-SignedHeaders", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Credential")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Credential", valid_603441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_GetDeleteDBCluster_603427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603442, url, valid)

proc call*(call_603443: Call_GetDeleteDBCluster_603427;
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
  var query_603444 = newJObject()
  add(query_603444, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603444, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603444, "Action", newJString(Action))
  add(query_603444, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603444, "Version", newJString(Version))
  result = call_603443.call(nil, query_603444, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_603427(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_603428,
    base: "/", url: url_GetDeleteDBCluster_603429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_603480 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBClusterParameterGroup_603482(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_603481(path: JsonNode;
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
  var valid_603483 = query.getOrDefault("Action")
  valid_603483 = validateParameter(valid_603483, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
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
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603492 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "DBClusterParameterGroupName", valid_603492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_PostDeleteDBClusterParameterGroup_603480;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_PostDeleteDBClusterParameterGroup_603480;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_603495 = newJObject()
  var formData_603496 = newJObject()
  add(query_603495, "Action", newJString(Action))
  add(formData_603496, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603495, "Version", newJString(Version))
  result = call_603494.call(nil, query_603495, nil, formData_603496, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_603480(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_603481, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_603482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_603464 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBClusterParameterGroup_603466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_603465(path: JsonNode;
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
  var valid_603467 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603467 = validateParameter(valid_603467, JString, required = true,
                                 default = nil)
  if valid_603467 != nil:
    section.add "DBClusterParameterGroupName", valid_603467
  var valid_603468 = query.getOrDefault("Action")
  valid_603468 = validateParameter(valid_603468, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
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

proc call*(call_603477: Call_GetDeleteDBClusterParameterGroup_603464;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_603477.validator(path, query, header, formData, body)
  let scheme = call_603477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603477.url(scheme.get, call_603477.host, call_603477.base,
                         call_603477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603477, url, valid)

proc call*(call_603478: Call_GetDeleteDBClusterParameterGroup_603464;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603479 = newJObject()
  add(query_603479, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603479, "Action", newJString(Action))
  add(query_603479, "Version", newJString(Version))
  result = call_603478.call(nil, query_603479, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_603464(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_603465, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_603466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_603513 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBClusterSnapshot_603515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_603514(path: JsonNode; query: JsonNode;
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
  var valid_603516 = query.getOrDefault("Action")
  valid_603516 = validateParameter(valid_603516, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
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
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_603525 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = nil)
  if valid_603525 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_PostDeleteDBClusterSnapshot_603513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_PostDeleteDBClusterSnapshot_603513;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603528 = newJObject()
  var formData_603529 = newJObject()
  add(formData_603529, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603528, "Action", newJString(Action))
  add(query_603528, "Version", newJString(Version))
  result = call_603527.call(nil, query_603528, nil, formData_603529, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_603513(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_603514, base: "/",
    url: url_PostDeleteDBClusterSnapshot_603515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_603497 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBClusterSnapshot_603499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_603498(path: JsonNode; query: JsonNode;
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
  var valid_603500 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603500 = validateParameter(valid_603500, JString, required = true,
                                 default = nil)
  if valid_603500 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603500
  var valid_603501 = query.getOrDefault("Action")
  valid_603501 = validateParameter(valid_603501, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_603501 != nil:
    section.add "Action", valid_603501
  var valid_603502 = query.getOrDefault("Version")
  valid_603502 = validateParameter(valid_603502, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603502 != nil:
    section.add "Version", valid_603502
  result.add "query", section
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

proc call*(call_603510: Call_GetDeleteDBClusterSnapshot_603497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_603510.validator(path, query, header, formData, body)
  let scheme = call_603510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603510.url(scheme.get, call_603510.host, call_603510.base,
                         call_603510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603510, url, valid)

proc call*(call_603511: Call_GetDeleteDBClusterSnapshot_603497;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603512 = newJObject()
  add(query_603512, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603512, "Action", newJString(Action))
  add(query_603512, "Version", newJString(Version))
  result = call_603511.call(nil, query_603512, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_603497(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_603498, base: "/",
    url: url_GetDeleteDBClusterSnapshot_603499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603546 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBInstance_603548(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_603547(path: JsonNode; query: JsonNode;
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
  var valid_603549 = query.getOrDefault("Action")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
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
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603558 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = nil)
  if valid_603558 != nil:
    section.add "DBInstanceIdentifier", valid_603558
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_PostDeleteDBInstance_603546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_PostDeleteDBInstance_603546;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603561 = newJObject()
  var formData_603562 = newJObject()
  add(formData_603562, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603561, "Action", newJString(Action))
  add(query_603561, "Version", newJString(Version))
  result = call_603560.call(nil, query_603561, nil, formData_603562, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603546(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603547, base: "/",
    url: url_PostDeleteDBInstance_603548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603530 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBInstance_603532(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_603531(path: JsonNode; query: JsonNode;
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
  var valid_603533 = query.getOrDefault("Action")
  valid_603533 = validateParameter(valid_603533, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603533 != nil:
    section.add "Action", valid_603533
  var valid_603534 = query.getOrDefault("Version")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603534 != nil:
    section.add "Version", valid_603534
  var valid_603535 = query.getOrDefault("DBInstanceIdentifier")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = nil)
  if valid_603535 != nil:
    section.add "DBInstanceIdentifier", valid_603535
  result.add "query", section
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

proc call*(call_603543: Call_GetDeleteDBInstance_603530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_603543.validator(path, query, header, formData, body)
  let scheme = call_603543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603543.url(scheme.get, call_603543.host, call_603543.base,
                         call_603543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603543, url, valid)

proc call*(call_603544: Call_GetDeleteDBInstance_603530;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_603545 = newJObject()
  add(query_603545, "Action", newJString(Action))
  add(query_603545, "Version", newJString(Version))
  add(query_603545, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603544.call(nil, query_603545, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603530(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603531, base: "/",
    url: url_GetDeleteDBInstance_603532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603579 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSubnetGroup_603581(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_603580(path: JsonNode; query: JsonNode;
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
  var valid_603582 = query.getOrDefault("Action")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603582 != nil:
    section.add "Action", valid_603582
  var valid_603583 = query.getOrDefault("Version")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603583 != nil:
    section.add "Version", valid_603583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603584 = header.getOrDefault("X-Amz-Date")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Date", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Security-Token")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Security-Token", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603591 = formData.getOrDefault("DBSubnetGroupName")
  valid_603591 = validateParameter(valid_603591, JString, required = true,
                                 default = nil)
  if valid_603591 != nil:
    section.add "DBSubnetGroupName", valid_603591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_PostDeleteDBSubnetGroup_603579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_PostDeleteDBSubnetGroup_603579;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603594 = newJObject()
  var formData_603595 = newJObject()
  add(formData_603595, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603594, "Action", newJString(Action))
  add(query_603594, "Version", newJString(Version))
  result = call_603593.call(nil, query_603594, nil, formData_603595, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603579(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603580, base: "/",
    url: url_PostDeleteDBSubnetGroup_603581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603563 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSubnetGroup_603565(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_603564(path: JsonNode; query: JsonNode;
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
  var valid_603566 = query.getOrDefault("Action")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603566 != nil:
    section.add "Action", valid_603566
  var valid_603567 = query.getOrDefault("DBSubnetGroupName")
  valid_603567 = validateParameter(valid_603567, JString, required = true,
                                 default = nil)
  if valid_603567 != nil:
    section.add "DBSubnetGroupName", valid_603567
  var valid_603568 = query.getOrDefault("Version")
  valid_603568 = validateParameter(valid_603568, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603568 != nil:
    section.add "Version", valid_603568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603569 = header.getOrDefault("X-Amz-Date")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Date", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Security-Token")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Security-Token", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Algorithm")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Algorithm", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Signature")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Signature", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-SignedHeaders", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Credential")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Credential", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603576: Call_GetDeleteDBSubnetGroup_603563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_603576.validator(path, query, header, formData, body)
  let scheme = call_603576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603576.url(scheme.get, call_603576.host, call_603576.base,
                         call_603576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603576, url, valid)

proc call*(call_603577: Call_GetDeleteDBSubnetGroup_603563;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_603578 = newJObject()
  add(query_603578, "Action", newJString(Action))
  add(query_603578, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603578, "Version", newJString(Version))
  result = call_603577.call(nil, query_603578, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603563(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603564, base: "/",
    url: url_GetDeleteDBSubnetGroup_603565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_603615 = ref object of OpenApiRestCall_602450
proc url_PostDescribeCertificates_603617(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeCertificates_603616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
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
  var valid_603618 = query.getOrDefault("Action")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_603618 != nil:
    section.add "Action", valid_603618
  var valid_603619 = query.getOrDefault("Version")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603619 != nil:
    section.add "Version", valid_603619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603620 = header.getOrDefault("X-Amz-Date")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Date", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Security-Token")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Security-Token", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
  result.add "header", section
  ## parameters in `formData` object:
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  section = newJObject()
  var valid_603627 = formData.getOrDefault("CertificateIdentifier")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "CertificateIdentifier", valid_603627
  var valid_603628 = formData.getOrDefault("Marker")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "Marker", valid_603628
  var valid_603629 = formData.getOrDefault("Filters")
  valid_603629 = validateParameter(valid_603629, JArray, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "Filters", valid_603629
  var valid_603630 = formData.getOrDefault("MaxRecords")
  valid_603630 = validateParameter(valid_603630, JInt, required = false, default = nil)
  if valid_603630 != nil:
    section.add "MaxRecords", valid_603630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_PostDescribeCertificates_603615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_PostDescribeCertificates_603615;
          CertificateIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   Version: string (required)
  var query_603633 = newJObject()
  var formData_603634 = newJObject()
  add(formData_603634, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(formData_603634, "Marker", newJString(Marker))
  add(query_603633, "Action", newJString(Action))
  if Filters != nil:
    formData_603634.add "Filters", Filters
  add(formData_603634, "MaxRecords", newJInt(MaxRecords))
  add(query_603633, "Version", newJString(Version))
  result = call_603632.call(nil, query_603633, nil, formData_603634, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_603615(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_603616, base: "/",
    url: url_PostDescribeCertificates_603617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_603596 = ref object of OpenApiRestCall_602450
proc url_GetDescribeCertificates_603598(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeCertificates_603597(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603599 = query.getOrDefault("MaxRecords")
  valid_603599 = validateParameter(valid_603599, JInt, required = false, default = nil)
  if valid_603599 != nil:
    section.add "MaxRecords", valid_603599
  var valid_603600 = query.getOrDefault("CertificateIdentifier")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "CertificateIdentifier", valid_603600
  var valid_603601 = query.getOrDefault("Filters")
  valid_603601 = validateParameter(valid_603601, JArray, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "Filters", valid_603601
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603602 = query.getOrDefault("Action")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_603602 != nil:
    section.add "Action", valid_603602
  var valid_603603 = query.getOrDefault("Marker")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "Marker", valid_603603
  var valid_603604 = query.getOrDefault("Version")
  valid_603604 = validateParameter(valid_603604, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603604 != nil:
    section.add "Version", valid_603604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603612: Call_GetDescribeCertificates_603596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_GetDescribeCertificates_603596; MaxRecords: int = 0;
          CertificateIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeCertificates"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_603614 = newJObject()
  add(query_603614, "MaxRecords", newJInt(MaxRecords))
  add(query_603614, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_603614.add "Filters", Filters
  add(query_603614, "Action", newJString(Action))
  add(query_603614, "Marker", newJString(Marker))
  add(query_603614, "Version", newJString(Version))
  result = call_603613.call(nil, query_603614, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_603596(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_603597, base: "/",
    url: url_GetDescribeCertificates_603598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_603654 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBClusterParameterGroups_603656(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_603655(path: JsonNode;
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
  var valid_603657 = query.getOrDefault("Action")
  valid_603657 = validateParameter(valid_603657, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_603657 != nil:
    section.add "Action", valid_603657
  var valid_603658 = query.getOrDefault("Version")
  valid_603658 = validateParameter(valid_603658, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603658 != nil:
    section.add "Version", valid_603658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603659 = header.getOrDefault("X-Amz-Date")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Date", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Security-Token")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Security-Token", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Content-Sha256", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Algorithm")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Algorithm", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Signature")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Signature", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-SignedHeaders", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Credential")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Credential", valid_603665
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
  var valid_603666 = formData.getOrDefault("Marker")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "Marker", valid_603666
  var valid_603667 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "DBClusterParameterGroupName", valid_603667
  var valid_603668 = formData.getOrDefault("Filters")
  valid_603668 = validateParameter(valid_603668, JArray, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "Filters", valid_603668
  var valid_603669 = formData.getOrDefault("MaxRecords")
  valid_603669 = validateParameter(valid_603669, JInt, required = false, default = nil)
  if valid_603669 != nil:
    section.add "MaxRecords", valid_603669
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603670: Call_PostDescribeDBClusterParameterGroups_603654;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_603670.validator(path, query, header, formData, body)
  let scheme = call_603670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603670.url(scheme.get, call_603670.host, call_603670.base,
                         call_603670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603670, url, valid)

proc call*(call_603671: Call_PostDescribeDBClusterParameterGroups_603654;
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
  var query_603672 = newJObject()
  var formData_603673 = newJObject()
  add(formData_603673, "Marker", newJString(Marker))
  add(query_603672, "Action", newJString(Action))
  add(formData_603673, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_603673.add "Filters", Filters
  add(formData_603673, "MaxRecords", newJInt(MaxRecords))
  add(query_603672, "Version", newJString(Version))
  result = call_603671.call(nil, query_603672, nil, formData_603673, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_603654(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_603655, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_603656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_603635 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBClusterParameterGroups_603637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_603636(path: JsonNode;
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
  var valid_603638 = query.getOrDefault("MaxRecords")
  valid_603638 = validateParameter(valid_603638, JInt, required = false, default = nil)
  if valid_603638 != nil:
    section.add "MaxRecords", valid_603638
  var valid_603639 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "DBClusterParameterGroupName", valid_603639
  var valid_603640 = query.getOrDefault("Filters")
  valid_603640 = validateParameter(valid_603640, JArray, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "Filters", valid_603640
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603641 = query.getOrDefault("Action")
  valid_603641 = validateParameter(valid_603641, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_603641 != nil:
    section.add "Action", valid_603641
  var valid_603642 = query.getOrDefault("Marker")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "Marker", valid_603642
  var valid_603643 = query.getOrDefault("Version")
  valid_603643 = validateParameter(valid_603643, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603643 != nil:
    section.add "Version", valid_603643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603644 = header.getOrDefault("X-Amz-Date")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Date", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Security-Token")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Security-Token", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Content-Sha256", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Algorithm")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Algorithm", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Signature")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Signature", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-SignedHeaders", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Credential")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Credential", valid_603650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603651: Call_GetDescribeDBClusterParameterGroups_603635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_603651.validator(path, query, header, formData, body)
  let scheme = call_603651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603651.url(scheme.get, call_603651.host, call_603651.base,
                         call_603651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603651, url, valid)

proc call*(call_603652: Call_GetDescribeDBClusterParameterGroups_603635;
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
  var query_603653 = newJObject()
  add(query_603653, "MaxRecords", newJInt(MaxRecords))
  add(query_603653, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_603653.add "Filters", Filters
  add(query_603653, "Action", newJString(Action))
  add(query_603653, "Marker", newJString(Marker))
  add(query_603653, "Version", newJString(Version))
  result = call_603652.call(nil, query_603653, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_603635(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_603636, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_603637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_603694 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBClusterParameters_603696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameters_603695(path: JsonNode;
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
  var valid_603697 = query.getOrDefault("Action")
  valid_603697 = validateParameter(valid_603697, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_603697 != nil:
    section.add "Action", valid_603697
  var valid_603698 = query.getOrDefault("Version")
  valid_603698 = validateParameter(valid_603698, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603698 != nil:
    section.add "Version", valid_603698
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603699 = header.getOrDefault("X-Amz-Date")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Date", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Security-Token")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Security-Token", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Content-Sha256", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Algorithm")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Algorithm", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Signature")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Signature", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-SignedHeaders", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Credential")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Credential", valid_603705
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
  var valid_603706 = formData.getOrDefault("Marker")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "Marker", valid_603706
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603707 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603707 = validateParameter(valid_603707, JString, required = true,
                                 default = nil)
  if valid_603707 != nil:
    section.add "DBClusterParameterGroupName", valid_603707
  var valid_603708 = formData.getOrDefault("Filters")
  valid_603708 = validateParameter(valid_603708, JArray, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "Filters", valid_603708
  var valid_603709 = formData.getOrDefault("MaxRecords")
  valid_603709 = validateParameter(valid_603709, JInt, required = false, default = nil)
  if valid_603709 != nil:
    section.add "MaxRecords", valid_603709
  var valid_603710 = formData.getOrDefault("Source")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "Source", valid_603710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603711: Call_PostDescribeDBClusterParameters_603694;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_603711.validator(path, query, header, formData, body)
  let scheme = call_603711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603711.url(scheme.get, call_603711.host, call_603711.base,
                         call_603711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603711, url, valid)

proc call*(call_603712: Call_PostDescribeDBClusterParameters_603694;
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
  var query_603713 = newJObject()
  var formData_603714 = newJObject()
  add(formData_603714, "Marker", newJString(Marker))
  add(query_603713, "Action", newJString(Action))
  add(formData_603714, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_603714.add "Filters", Filters
  add(formData_603714, "MaxRecords", newJInt(MaxRecords))
  add(query_603713, "Version", newJString(Version))
  add(formData_603714, "Source", newJString(Source))
  result = call_603712.call(nil, query_603713, nil, formData_603714, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_603694(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_603695, base: "/",
    url: url_PostDescribeDBClusterParameters_603696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_603674 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBClusterParameters_603676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameters_603675(path: JsonNode;
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
  var valid_603677 = query.getOrDefault("MaxRecords")
  valid_603677 = validateParameter(valid_603677, JInt, required = false, default = nil)
  if valid_603677 != nil:
    section.add "MaxRecords", valid_603677
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603678 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603678 = validateParameter(valid_603678, JString, required = true,
                                 default = nil)
  if valid_603678 != nil:
    section.add "DBClusterParameterGroupName", valid_603678
  var valid_603679 = query.getOrDefault("Filters")
  valid_603679 = validateParameter(valid_603679, JArray, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "Filters", valid_603679
  var valid_603680 = query.getOrDefault("Action")
  valid_603680 = validateParameter(valid_603680, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_603680 != nil:
    section.add "Action", valid_603680
  var valid_603681 = query.getOrDefault("Marker")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "Marker", valid_603681
  var valid_603682 = query.getOrDefault("Source")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "Source", valid_603682
  var valid_603683 = query.getOrDefault("Version")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603683 != nil:
    section.add "Version", valid_603683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603684 = header.getOrDefault("X-Amz-Date")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Date", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Security-Token")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Security-Token", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Content-Sha256", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Algorithm")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Algorithm", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Signature")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Signature", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-SignedHeaders", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Credential")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Credential", valid_603690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603691: Call_GetDescribeDBClusterParameters_603674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_GetDescribeDBClusterParameters_603674;
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
  var query_603693 = newJObject()
  add(query_603693, "MaxRecords", newJInt(MaxRecords))
  add(query_603693, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_603693.add "Filters", Filters
  add(query_603693, "Action", newJString(Action))
  add(query_603693, "Marker", newJString(Marker))
  add(query_603693, "Source", newJString(Source))
  add(query_603693, "Version", newJString(Version))
  result = call_603692.call(nil, query_603693, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_603674(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_603675, base: "/",
    url: url_GetDescribeDBClusterParameters_603676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_603731 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBClusterSnapshotAttributes_603733(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_603732(path: JsonNode;
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
  var valid_603734 = query.getOrDefault("Action")
  valid_603734 = validateParameter(valid_603734, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_603734 != nil:
    section.add "Action", valid_603734
  var valid_603735 = query.getOrDefault("Version")
  valid_603735 = validateParameter(valid_603735, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603735 != nil:
    section.add "Version", valid_603735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603736 = header.getOrDefault("X-Amz-Date")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Date", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Security-Token")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Security-Token", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Content-Sha256", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Algorithm")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Algorithm", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Signature")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Signature", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-SignedHeaders", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Credential")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Credential", valid_603742
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_603743 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603743 = validateParameter(valid_603743, JString, required = true,
                                 default = nil)
  if valid_603743 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603744: Call_PostDescribeDBClusterSnapshotAttributes_603731;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_603744.validator(path, query, header, formData, body)
  let scheme = call_603744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603744.url(scheme.get, call_603744.host, call_603744.base,
                         call_603744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603744, url, valid)

proc call*(call_603745: Call_PostDescribeDBClusterSnapshotAttributes_603731;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603746 = newJObject()
  var formData_603747 = newJObject()
  add(formData_603747, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603746, "Action", newJString(Action))
  add(query_603746, "Version", newJString(Version))
  result = call_603745.call(nil, query_603746, nil, formData_603747, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_603731(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_603732, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_603733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_603715 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBClusterSnapshotAttributes_603717(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_603716(path: JsonNode;
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
  var valid_603718 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603718 = validateParameter(valid_603718, JString, required = true,
                                 default = nil)
  if valid_603718 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603718
  var valid_603719 = query.getOrDefault("Action")
  valid_603719 = validateParameter(valid_603719, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_603719 != nil:
    section.add "Action", valid_603719
  var valid_603720 = query.getOrDefault("Version")
  valid_603720 = validateParameter(valid_603720, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603720 != nil:
    section.add "Version", valid_603720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603721 = header.getOrDefault("X-Amz-Date")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Date", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Security-Token")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Security-Token", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Content-Sha256", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Algorithm")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Algorithm", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Signature")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Signature", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-SignedHeaders", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Credential")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Credential", valid_603727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603728: Call_GetDescribeDBClusterSnapshotAttributes_603715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_603728.validator(path, query, header, formData, body)
  let scheme = call_603728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603728.url(scheme.get, call_603728.host, call_603728.base,
                         call_603728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603728, url, valid)

proc call*(call_603729: Call_GetDescribeDBClusterSnapshotAttributes_603715;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603730 = newJObject()
  add(query_603730, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603730, "Action", newJString(Action))
  add(query_603730, "Version", newJString(Version))
  result = call_603729.call(nil, query_603730, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_603715(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_603716, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_603717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_603771 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBClusterSnapshots_603773(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_603772(path: JsonNode;
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
  var valid_603774 = query.getOrDefault("Action")
  valid_603774 = validateParameter(valid_603774, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_603774 != nil:
    section.add "Action", valid_603774
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
  var valid_603783 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603783
  var valid_603784 = formData.getOrDefault("IncludeShared")
  valid_603784 = validateParameter(valid_603784, JBool, required = false, default = nil)
  if valid_603784 != nil:
    section.add "IncludeShared", valid_603784
  var valid_603785 = formData.getOrDefault("IncludePublic")
  valid_603785 = validateParameter(valid_603785, JBool, required = false, default = nil)
  if valid_603785 != nil:
    section.add "IncludePublic", valid_603785
  var valid_603786 = formData.getOrDefault("SnapshotType")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "SnapshotType", valid_603786
  var valid_603787 = formData.getOrDefault("Marker")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "Marker", valid_603787
  var valid_603788 = formData.getOrDefault("Filters")
  valid_603788 = validateParameter(valid_603788, JArray, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "Filters", valid_603788
  var valid_603789 = formData.getOrDefault("MaxRecords")
  valid_603789 = validateParameter(valid_603789, JInt, required = false, default = nil)
  if valid_603789 != nil:
    section.add "MaxRecords", valid_603789
  var valid_603790 = formData.getOrDefault("DBClusterIdentifier")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "DBClusterIdentifier", valid_603790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603791: Call_PostDescribeDBClusterSnapshots_603771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_603791.validator(path, query, header, formData, body)
  let scheme = call_603791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603791.url(scheme.get, call_603791.host, call_603791.base,
                         call_603791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603791, url, valid)

proc call*(call_603792: Call_PostDescribeDBClusterSnapshots_603771;
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
  var query_603793 = newJObject()
  var formData_603794 = newJObject()
  add(formData_603794, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_603794, "IncludeShared", newJBool(IncludeShared))
  add(formData_603794, "IncludePublic", newJBool(IncludePublic))
  add(formData_603794, "SnapshotType", newJString(SnapshotType))
  add(formData_603794, "Marker", newJString(Marker))
  add(query_603793, "Action", newJString(Action))
  if Filters != nil:
    formData_603794.add "Filters", Filters
  add(formData_603794, "MaxRecords", newJInt(MaxRecords))
  add(formData_603794, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603793, "Version", newJString(Version))
  result = call_603792.call(nil, query_603793, nil, formData_603794, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_603771(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_603772, base: "/",
    url: url_PostDescribeDBClusterSnapshots_603773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_603748 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBClusterSnapshots_603750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_603749(path: JsonNode; query: JsonNode;
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
  var valid_603751 = query.getOrDefault("IncludePublic")
  valid_603751 = validateParameter(valid_603751, JBool, required = false, default = nil)
  if valid_603751 != nil:
    section.add "IncludePublic", valid_603751
  var valid_603752 = query.getOrDefault("MaxRecords")
  valid_603752 = validateParameter(valid_603752, JInt, required = false, default = nil)
  if valid_603752 != nil:
    section.add "MaxRecords", valid_603752
  var valid_603753 = query.getOrDefault("DBClusterIdentifier")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "DBClusterIdentifier", valid_603753
  var valid_603754 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603754
  var valid_603755 = query.getOrDefault("Filters")
  valid_603755 = validateParameter(valid_603755, JArray, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "Filters", valid_603755
  var valid_603756 = query.getOrDefault("IncludeShared")
  valid_603756 = validateParameter(valid_603756, JBool, required = false, default = nil)
  if valid_603756 != nil:
    section.add "IncludeShared", valid_603756
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603757 = query.getOrDefault("Action")
  valid_603757 = validateParameter(valid_603757, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_603757 != nil:
    section.add "Action", valid_603757
  var valid_603758 = query.getOrDefault("Marker")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "Marker", valid_603758
  var valid_603759 = query.getOrDefault("SnapshotType")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "SnapshotType", valid_603759
  var valid_603760 = query.getOrDefault("Version")
  valid_603760 = validateParameter(valid_603760, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603760 != nil:
    section.add "Version", valid_603760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603761 = header.getOrDefault("X-Amz-Date")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Date", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Security-Token")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Security-Token", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Content-Sha256", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Algorithm")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Algorithm", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Signature")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Signature", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-SignedHeaders", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Credential")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Credential", valid_603767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603768: Call_GetDescribeDBClusterSnapshots_603748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_603768.validator(path, query, header, formData, body)
  let scheme = call_603768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603768.url(scheme.get, call_603768.host, call_603768.base,
                         call_603768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603768, url, valid)

proc call*(call_603769: Call_GetDescribeDBClusterSnapshots_603748;
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
  var query_603770 = newJObject()
  add(query_603770, "IncludePublic", newJBool(IncludePublic))
  add(query_603770, "MaxRecords", newJInt(MaxRecords))
  add(query_603770, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603770, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_603770.add "Filters", Filters
  add(query_603770, "IncludeShared", newJBool(IncludeShared))
  add(query_603770, "Action", newJString(Action))
  add(query_603770, "Marker", newJString(Marker))
  add(query_603770, "SnapshotType", newJString(SnapshotType))
  add(query_603770, "Version", newJString(Version))
  result = call_603769.call(nil, query_603770, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_603748(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_603749, base: "/",
    url: url_GetDescribeDBClusterSnapshots_603750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_603814 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBClusters_603816(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusters_603815(path: JsonNode; query: JsonNode;
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
  var valid_603817 = query.getOrDefault("Action")
  valid_603817 = validateParameter(valid_603817, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_603817 != nil:
    section.add "Action", valid_603817
  var valid_603818 = query.getOrDefault("Version")
  valid_603818 = validateParameter(valid_603818, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603818 != nil:
    section.add "Version", valid_603818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603819 = header.getOrDefault("X-Amz-Date")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Date", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Security-Token")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Security-Token", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Content-Sha256", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Algorithm")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Algorithm", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Signature")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Signature", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-SignedHeaders", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Credential")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Credential", valid_603825
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
  var valid_603826 = formData.getOrDefault("Marker")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "Marker", valid_603826
  var valid_603827 = formData.getOrDefault("Filters")
  valid_603827 = validateParameter(valid_603827, JArray, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "Filters", valid_603827
  var valid_603828 = formData.getOrDefault("MaxRecords")
  valid_603828 = validateParameter(valid_603828, JInt, required = false, default = nil)
  if valid_603828 != nil:
    section.add "MaxRecords", valid_603828
  var valid_603829 = formData.getOrDefault("DBClusterIdentifier")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "DBClusterIdentifier", valid_603829
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_PostDescribeDBClusters_603814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_PostDescribeDBClusters_603814; Marker: string = "";
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
  var query_603832 = newJObject()
  var formData_603833 = newJObject()
  add(formData_603833, "Marker", newJString(Marker))
  add(query_603832, "Action", newJString(Action))
  if Filters != nil:
    formData_603833.add "Filters", Filters
  add(formData_603833, "MaxRecords", newJInt(MaxRecords))
  add(formData_603833, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603832, "Version", newJString(Version))
  result = call_603831.call(nil, query_603832, nil, formData_603833, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_603814(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_603815, base: "/",
    url: url_PostDescribeDBClusters_603816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_603795 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBClusters_603797(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusters_603796(path: JsonNode; query: JsonNode;
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
  var valid_603798 = query.getOrDefault("MaxRecords")
  valid_603798 = validateParameter(valid_603798, JInt, required = false, default = nil)
  if valid_603798 != nil:
    section.add "MaxRecords", valid_603798
  var valid_603799 = query.getOrDefault("DBClusterIdentifier")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "DBClusterIdentifier", valid_603799
  var valid_603800 = query.getOrDefault("Filters")
  valid_603800 = validateParameter(valid_603800, JArray, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Filters", valid_603800
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603801 = query.getOrDefault("Action")
  valid_603801 = validateParameter(valid_603801, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_603801 != nil:
    section.add "Action", valid_603801
  var valid_603802 = query.getOrDefault("Marker")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "Marker", valid_603802
  var valid_603803 = query.getOrDefault("Version")
  valid_603803 = validateParameter(valid_603803, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603803 != nil:
    section.add "Version", valid_603803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603804 = header.getOrDefault("X-Amz-Date")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Date", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Security-Token")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Security-Token", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Content-Sha256", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Algorithm")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Algorithm", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Signature")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Signature", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-SignedHeaders", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Credential")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Credential", valid_603810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603811: Call_GetDescribeDBClusters_603795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_603811.validator(path, query, header, formData, body)
  let scheme = call_603811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603811.url(scheme.get, call_603811.host, call_603811.base,
                         call_603811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603811, url, valid)

proc call*(call_603812: Call_GetDescribeDBClusters_603795; MaxRecords: int = 0;
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
  var query_603813 = newJObject()
  add(query_603813, "MaxRecords", newJInt(MaxRecords))
  add(query_603813, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_603813.add "Filters", Filters
  add(query_603813, "Action", newJString(Action))
  add(query_603813, "Marker", newJString(Marker))
  add(query_603813, "Version", newJString(Version))
  result = call_603812.call(nil, query_603813, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_603795(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_603796, base: "/",
    url: url_GetDescribeDBClusters_603797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603858 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBEngineVersions_603860(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_603859(path: JsonNode; query: JsonNode;
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
  var valid_603861 = query.getOrDefault("Action")
  valid_603861 = validateParameter(valid_603861, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603861 != nil:
    section.add "Action", valid_603861
  var valid_603862 = query.getOrDefault("Version")
  valid_603862 = validateParameter(valid_603862, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603862 != nil:
    section.add "Version", valid_603862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603863 = header.getOrDefault("X-Amz-Date")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Date", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Security-Token")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Security-Token", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Content-Sha256", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Algorithm")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Algorithm", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Signature")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Signature", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-SignedHeaders", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Credential")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Credential", valid_603869
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
  var valid_603870 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603870 = validateParameter(valid_603870, JBool, required = false, default = nil)
  if valid_603870 != nil:
    section.add "ListSupportedCharacterSets", valid_603870
  var valid_603871 = formData.getOrDefault("Engine")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "Engine", valid_603871
  var valid_603872 = formData.getOrDefault("Marker")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "Marker", valid_603872
  var valid_603873 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "DBParameterGroupFamily", valid_603873
  var valid_603874 = formData.getOrDefault("Filters")
  valid_603874 = validateParameter(valid_603874, JArray, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "Filters", valid_603874
  var valid_603875 = formData.getOrDefault("MaxRecords")
  valid_603875 = validateParameter(valid_603875, JInt, required = false, default = nil)
  if valid_603875 != nil:
    section.add "MaxRecords", valid_603875
  var valid_603876 = formData.getOrDefault("EngineVersion")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "EngineVersion", valid_603876
  var valid_603877 = formData.getOrDefault("ListSupportedTimezones")
  valid_603877 = validateParameter(valid_603877, JBool, required = false, default = nil)
  if valid_603877 != nil:
    section.add "ListSupportedTimezones", valid_603877
  var valid_603878 = formData.getOrDefault("DefaultOnly")
  valid_603878 = validateParameter(valid_603878, JBool, required = false, default = nil)
  if valid_603878 != nil:
    section.add "DefaultOnly", valid_603878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603879: Call_PostDescribeDBEngineVersions_603858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_603879.validator(path, query, header, formData, body)
  let scheme = call_603879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603879.url(scheme.get, call_603879.host, call_603879.base,
                         call_603879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603879, url, valid)

proc call*(call_603880: Call_PostDescribeDBEngineVersions_603858;
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
  var query_603881 = newJObject()
  var formData_603882 = newJObject()
  add(formData_603882, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603882, "Engine", newJString(Engine))
  add(formData_603882, "Marker", newJString(Marker))
  add(query_603881, "Action", newJString(Action))
  add(formData_603882, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603882.add "Filters", Filters
  add(formData_603882, "MaxRecords", newJInt(MaxRecords))
  add(formData_603882, "EngineVersion", newJString(EngineVersion))
  add(formData_603882, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_603881, "Version", newJString(Version))
  add(formData_603882, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603880.call(nil, query_603881, nil, formData_603882, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603858(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603859, base: "/",
    url: url_PostDescribeDBEngineVersions_603860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603834 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBEngineVersions_603836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_603835(path: JsonNode; query: JsonNode;
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
  var valid_603837 = query.getOrDefault("Engine")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "Engine", valid_603837
  var valid_603838 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603838 = validateParameter(valid_603838, JBool, required = false, default = nil)
  if valid_603838 != nil:
    section.add "ListSupportedCharacterSets", valid_603838
  var valid_603839 = query.getOrDefault("MaxRecords")
  valid_603839 = validateParameter(valid_603839, JInt, required = false, default = nil)
  if valid_603839 != nil:
    section.add "MaxRecords", valid_603839
  var valid_603840 = query.getOrDefault("DBParameterGroupFamily")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "DBParameterGroupFamily", valid_603840
  var valid_603841 = query.getOrDefault("Filters")
  valid_603841 = validateParameter(valid_603841, JArray, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "Filters", valid_603841
  var valid_603842 = query.getOrDefault("ListSupportedTimezones")
  valid_603842 = validateParameter(valid_603842, JBool, required = false, default = nil)
  if valid_603842 != nil:
    section.add "ListSupportedTimezones", valid_603842
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603843 = query.getOrDefault("Action")
  valid_603843 = validateParameter(valid_603843, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603843 != nil:
    section.add "Action", valid_603843
  var valid_603844 = query.getOrDefault("Marker")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "Marker", valid_603844
  var valid_603845 = query.getOrDefault("EngineVersion")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "EngineVersion", valid_603845
  var valid_603846 = query.getOrDefault("DefaultOnly")
  valid_603846 = validateParameter(valid_603846, JBool, required = false, default = nil)
  if valid_603846 != nil:
    section.add "DefaultOnly", valid_603846
  var valid_603847 = query.getOrDefault("Version")
  valid_603847 = validateParameter(valid_603847, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603847 != nil:
    section.add "Version", valid_603847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603848 = header.getOrDefault("X-Amz-Date")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Date", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Security-Token")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Security-Token", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Content-Sha256", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Algorithm")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Algorithm", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Signature")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Signature", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-SignedHeaders", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Credential")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Credential", valid_603854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603855: Call_GetDescribeDBEngineVersions_603834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_603855.validator(path, query, header, formData, body)
  let scheme = call_603855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603855.url(scheme.get, call_603855.host, call_603855.base,
                         call_603855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603855, url, valid)

proc call*(call_603856: Call_GetDescribeDBEngineVersions_603834;
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
  var query_603857 = newJObject()
  add(query_603857, "Engine", newJString(Engine))
  add(query_603857, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603857, "MaxRecords", newJInt(MaxRecords))
  add(query_603857, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603857.add "Filters", Filters
  add(query_603857, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_603857, "Action", newJString(Action))
  add(query_603857, "Marker", newJString(Marker))
  add(query_603857, "EngineVersion", newJString(EngineVersion))
  add(query_603857, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603857, "Version", newJString(Version))
  result = call_603856.call(nil, query_603857, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603834(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603835, base: "/",
    url: url_GetDescribeDBEngineVersions_603836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603902 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBInstances_603904(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_603903(path: JsonNode; query: JsonNode;
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
  var valid_603905 = query.getOrDefault("Action")
  valid_603905 = validateParameter(valid_603905, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603905 != nil:
    section.add "Action", valid_603905
  var valid_603906 = query.getOrDefault("Version")
  valid_603906 = validateParameter(valid_603906, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603906 != nil:
    section.add "Version", valid_603906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603907 = header.getOrDefault("X-Amz-Date")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Date", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Security-Token")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Security-Token", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Content-Sha256", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Algorithm")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Algorithm", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Signature")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Signature", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-SignedHeaders", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Credential")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Credential", valid_603913
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
  var valid_603914 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "DBInstanceIdentifier", valid_603914
  var valid_603915 = formData.getOrDefault("Marker")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "Marker", valid_603915
  var valid_603916 = formData.getOrDefault("Filters")
  valid_603916 = validateParameter(valid_603916, JArray, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "Filters", valid_603916
  var valid_603917 = formData.getOrDefault("MaxRecords")
  valid_603917 = validateParameter(valid_603917, JInt, required = false, default = nil)
  if valid_603917 != nil:
    section.add "MaxRecords", valid_603917
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603918: Call_PostDescribeDBInstances_603902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_603918.validator(path, query, header, formData, body)
  let scheme = call_603918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603918.url(scheme.get, call_603918.host, call_603918.base,
                         call_603918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603918, url, valid)

proc call*(call_603919: Call_PostDescribeDBInstances_603902;
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
  var query_603920 = newJObject()
  var formData_603921 = newJObject()
  add(formData_603921, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603921, "Marker", newJString(Marker))
  add(query_603920, "Action", newJString(Action))
  if Filters != nil:
    formData_603921.add "Filters", Filters
  add(formData_603921, "MaxRecords", newJInt(MaxRecords))
  add(query_603920, "Version", newJString(Version))
  result = call_603919.call(nil, query_603920, nil, formData_603921, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603902(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603903, base: "/",
    url: url_PostDescribeDBInstances_603904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603883 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBInstances_603885(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_603884(path: JsonNode; query: JsonNode;
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
  var valid_603886 = query.getOrDefault("MaxRecords")
  valid_603886 = validateParameter(valid_603886, JInt, required = false, default = nil)
  if valid_603886 != nil:
    section.add "MaxRecords", valid_603886
  var valid_603887 = query.getOrDefault("Filters")
  valid_603887 = validateParameter(valid_603887, JArray, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "Filters", valid_603887
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603888 = query.getOrDefault("Action")
  valid_603888 = validateParameter(valid_603888, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603888 != nil:
    section.add "Action", valid_603888
  var valid_603889 = query.getOrDefault("Marker")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "Marker", valid_603889
  var valid_603890 = query.getOrDefault("Version")
  valid_603890 = validateParameter(valid_603890, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603890 != nil:
    section.add "Version", valid_603890
  var valid_603891 = query.getOrDefault("DBInstanceIdentifier")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "DBInstanceIdentifier", valid_603891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603892 = header.getOrDefault("X-Amz-Date")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Date", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Security-Token")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Security-Token", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Content-Sha256", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Algorithm")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Algorithm", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Signature")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Signature", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-SignedHeaders", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Credential")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Credential", valid_603898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603899: Call_GetDescribeDBInstances_603883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_603899.validator(path, query, header, formData, body)
  let scheme = call_603899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603899.url(scheme.get, call_603899.host, call_603899.base,
                         call_603899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603899, url, valid)

proc call*(call_603900: Call_GetDescribeDBInstances_603883; MaxRecords: int = 0;
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
  var query_603901 = newJObject()
  add(query_603901, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603901.add "Filters", Filters
  add(query_603901, "Action", newJString(Action))
  add(query_603901, "Marker", newJString(Marker))
  add(query_603901, "Version", newJString(Version))
  add(query_603901, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603900.call(nil, query_603901, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603883(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603884, base: "/",
    url: url_GetDescribeDBInstances_603885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_603941 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSubnetGroups_603943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_603942(path: JsonNode; query: JsonNode;
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
  var valid_603944 = query.getOrDefault("Action")
  valid_603944 = validateParameter(valid_603944, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603944 != nil:
    section.add "Action", valid_603944
  var valid_603945 = query.getOrDefault("Version")
  valid_603945 = validateParameter(valid_603945, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603945 != nil:
    section.add "Version", valid_603945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603946 = header.getOrDefault("X-Amz-Date")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Date", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Security-Token")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Security-Token", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Content-Sha256", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Algorithm")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Algorithm", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Signature")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Signature", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-SignedHeaders", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Credential")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Credential", valid_603952
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
  var valid_603953 = formData.getOrDefault("DBSubnetGroupName")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "DBSubnetGroupName", valid_603953
  var valid_603954 = formData.getOrDefault("Marker")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "Marker", valid_603954
  var valid_603955 = formData.getOrDefault("Filters")
  valid_603955 = validateParameter(valid_603955, JArray, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "Filters", valid_603955
  var valid_603956 = formData.getOrDefault("MaxRecords")
  valid_603956 = validateParameter(valid_603956, JInt, required = false, default = nil)
  if valid_603956 != nil:
    section.add "MaxRecords", valid_603956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603957: Call_PostDescribeDBSubnetGroups_603941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_603957.validator(path, query, header, formData, body)
  let scheme = call_603957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603957.url(scheme.get, call_603957.host, call_603957.base,
                         call_603957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603957, url, valid)

proc call*(call_603958: Call_PostDescribeDBSubnetGroups_603941;
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
  var query_603959 = newJObject()
  var formData_603960 = newJObject()
  add(formData_603960, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603960, "Marker", newJString(Marker))
  add(query_603959, "Action", newJString(Action))
  if Filters != nil:
    formData_603960.add "Filters", Filters
  add(formData_603960, "MaxRecords", newJInt(MaxRecords))
  add(query_603959, "Version", newJString(Version))
  result = call_603958.call(nil, query_603959, nil, formData_603960, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_603941(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_603942, base: "/",
    url: url_PostDescribeDBSubnetGroups_603943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_603922 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSubnetGroups_603924(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_603923(path: JsonNode; query: JsonNode;
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
  var valid_603925 = query.getOrDefault("MaxRecords")
  valid_603925 = validateParameter(valid_603925, JInt, required = false, default = nil)
  if valid_603925 != nil:
    section.add "MaxRecords", valid_603925
  var valid_603926 = query.getOrDefault("Filters")
  valid_603926 = validateParameter(valid_603926, JArray, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "Filters", valid_603926
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603927 = query.getOrDefault("Action")
  valid_603927 = validateParameter(valid_603927, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603927 != nil:
    section.add "Action", valid_603927
  var valid_603928 = query.getOrDefault("Marker")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "Marker", valid_603928
  var valid_603929 = query.getOrDefault("DBSubnetGroupName")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "DBSubnetGroupName", valid_603929
  var valid_603930 = query.getOrDefault("Version")
  valid_603930 = validateParameter(valid_603930, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603930 != nil:
    section.add "Version", valid_603930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603931 = header.getOrDefault("X-Amz-Date")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Date", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Security-Token")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Security-Token", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Content-Sha256", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Algorithm")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Algorithm", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Signature")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Signature", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-SignedHeaders", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Credential")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Credential", valid_603937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603938: Call_GetDescribeDBSubnetGroups_603922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_603938.validator(path, query, header, formData, body)
  let scheme = call_603938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603938.url(scheme.get, call_603938.host, call_603938.base,
                         call_603938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603938, url, valid)

proc call*(call_603939: Call_GetDescribeDBSubnetGroups_603922; MaxRecords: int = 0;
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
  var query_603940 = newJObject()
  add(query_603940, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603940.add "Filters", Filters
  add(query_603940, "Action", newJString(Action))
  add(query_603940, "Marker", newJString(Marker))
  add(query_603940, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603940, "Version", newJString(Version))
  result = call_603939.call(nil, query_603940, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_603922(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_603923, base: "/",
    url: url_GetDescribeDBSubnetGroups_603924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_603980 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEngineDefaultClusterParameters_603982(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_603981(path: JsonNode;
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
  var valid_603983 = query.getOrDefault("Action")
  valid_603983 = validateParameter(valid_603983, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_603983 != nil:
    section.add "Action", valid_603983
  var valid_603984 = query.getOrDefault("Version")
  valid_603984 = validateParameter(valid_603984, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603984 != nil:
    section.add "Version", valid_603984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603985 = header.getOrDefault("X-Amz-Date")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Date", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Security-Token")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Security-Token", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Content-Sha256", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Algorithm")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Algorithm", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Signature")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Signature", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-SignedHeaders", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Credential")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Credential", valid_603991
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
  var valid_603992 = formData.getOrDefault("Marker")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "Marker", valid_603992
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603993 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603993 = validateParameter(valid_603993, JString, required = true,
                                 default = nil)
  if valid_603993 != nil:
    section.add "DBParameterGroupFamily", valid_603993
  var valid_603994 = formData.getOrDefault("Filters")
  valid_603994 = validateParameter(valid_603994, JArray, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "Filters", valid_603994
  var valid_603995 = formData.getOrDefault("MaxRecords")
  valid_603995 = validateParameter(valid_603995, JInt, required = false, default = nil)
  if valid_603995 != nil:
    section.add "MaxRecords", valid_603995
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603996: Call_PostDescribeEngineDefaultClusterParameters_603980;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_603996.validator(path, query, header, formData, body)
  let scheme = call_603996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603996.url(scheme.get, call_603996.host, call_603996.base,
                         call_603996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603996, url, valid)

proc call*(call_603997: Call_PostDescribeEngineDefaultClusterParameters_603980;
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
  var query_603998 = newJObject()
  var formData_603999 = newJObject()
  add(formData_603999, "Marker", newJString(Marker))
  add(query_603998, "Action", newJString(Action))
  add(formData_603999, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603999.add "Filters", Filters
  add(formData_603999, "MaxRecords", newJInt(MaxRecords))
  add(query_603998, "Version", newJString(Version))
  result = call_603997.call(nil, query_603998, nil, formData_603999, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_603980(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_603981,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_603982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_603961 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEngineDefaultClusterParameters_603963(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_603962(path: JsonNode;
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
  var valid_603964 = query.getOrDefault("MaxRecords")
  valid_603964 = validateParameter(valid_603964, JInt, required = false, default = nil)
  if valid_603964 != nil:
    section.add "MaxRecords", valid_603964
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603965 = query.getOrDefault("DBParameterGroupFamily")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = nil)
  if valid_603965 != nil:
    section.add "DBParameterGroupFamily", valid_603965
  var valid_603966 = query.getOrDefault("Filters")
  valid_603966 = validateParameter(valid_603966, JArray, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "Filters", valid_603966
  var valid_603967 = query.getOrDefault("Action")
  valid_603967 = validateParameter(valid_603967, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_603967 != nil:
    section.add "Action", valid_603967
  var valid_603968 = query.getOrDefault("Marker")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "Marker", valid_603968
  var valid_603969 = query.getOrDefault("Version")
  valid_603969 = validateParameter(valid_603969, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603969 != nil:
    section.add "Version", valid_603969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603970 = header.getOrDefault("X-Amz-Date")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Date", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Security-Token")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Security-Token", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Content-Sha256", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Algorithm")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Algorithm", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Signature")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Signature", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-SignedHeaders", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Credential")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Credential", valid_603976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603977: Call_GetDescribeEngineDefaultClusterParameters_603961;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_603977.validator(path, query, header, formData, body)
  let scheme = call_603977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603977.url(scheme.get, call_603977.host, call_603977.base,
                         call_603977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603977, url, valid)

proc call*(call_603978: Call_GetDescribeEngineDefaultClusterParameters_603961;
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
  var query_603979 = newJObject()
  add(query_603979, "MaxRecords", newJInt(MaxRecords))
  add(query_603979, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603979.add "Filters", Filters
  add(query_603979, "Action", newJString(Action))
  add(query_603979, "Marker", newJString(Marker))
  add(query_603979, "Version", newJString(Version))
  result = call_603978.call(nil, query_603979, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_603961(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_603962,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_603963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604017 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventCategories_604019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_604018(path: JsonNode; query: JsonNode;
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
  var valid_604020 = query.getOrDefault("Action")
  valid_604020 = validateParameter(valid_604020, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604020 != nil:
    section.add "Action", valid_604020
  var valid_604021 = query.getOrDefault("Version")
  valid_604021 = validateParameter(valid_604021, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604021 != nil:
    section.add "Version", valid_604021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604022 = header.getOrDefault("X-Amz-Date")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Date", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Security-Token")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Security-Token", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Content-Sha256", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Algorithm")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Algorithm", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Signature")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Signature", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-SignedHeaders", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Credential")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Credential", valid_604028
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_604029 = formData.getOrDefault("Filters")
  valid_604029 = validateParameter(valid_604029, JArray, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "Filters", valid_604029
  var valid_604030 = formData.getOrDefault("SourceType")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "SourceType", valid_604030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604031: Call_PostDescribeEventCategories_604017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_604031.validator(path, query, header, formData, body)
  let scheme = call_604031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604031.url(scheme.get, call_604031.host, call_604031.base,
                         call_604031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604031, url, valid)

proc call*(call_604032: Call_PostDescribeEventCategories_604017;
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
  var query_604033 = newJObject()
  var formData_604034 = newJObject()
  add(query_604033, "Action", newJString(Action))
  if Filters != nil:
    formData_604034.add "Filters", Filters
  add(query_604033, "Version", newJString(Version))
  add(formData_604034, "SourceType", newJString(SourceType))
  result = call_604032.call(nil, query_604033, nil, formData_604034, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604017(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604018, base: "/",
    url: url_PostDescribeEventCategories_604019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604000 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventCategories_604002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_604001(path: JsonNode; query: JsonNode;
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
  var valid_604003 = query.getOrDefault("SourceType")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "SourceType", valid_604003
  var valid_604004 = query.getOrDefault("Filters")
  valid_604004 = validateParameter(valid_604004, JArray, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "Filters", valid_604004
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604005 = query.getOrDefault("Action")
  valid_604005 = validateParameter(valid_604005, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604005 != nil:
    section.add "Action", valid_604005
  var valid_604006 = query.getOrDefault("Version")
  valid_604006 = validateParameter(valid_604006, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604006 != nil:
    section.add "Version", valid_604006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604007 = header.getOrDefault("X-Amz-Date")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Date", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Security-Token")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Security-Token", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Content-Sha256", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Algorithm")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Algorithm", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Signature")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Signature", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-SignedHeaders", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Credential")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Credential", valid_604013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604014: Call_GetDescribeEventCategories_604000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_604014.validator(path, query, header, formData, body)
  let scheme = call_604014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604014.url(scheme.get, call_604014.host, call_604014.base,
                         call_604014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604014, url, valid)

proc call*(call_604015: Call_GetDescribeEventCategories_604000;
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
  var query_604016 = newJObject()
  add(query_604016, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_604016.add "Filters", Filters
  add(query_604016, "Action", newJString(Action))
  add(query_604016, "Version", newJString(Version))
  result = call_604015.call(nil, query_604016, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604000(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604001, base: "/",
    url: url_GetDescribeEventCategories_604002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604059 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEvents_604061(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604060(path: JsonNode; query: JsonNode;
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
  var valid_604062 = query.getOrDefault("Action")
  valid_604062 = validateParameter(valid_604062, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604062 != nil:
    section.add "Action", valid_604062
  var valid_604063 = query.getOrDefault("Version")
  valid_604063 = validateParameter(valid_604063, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604063 != nil:
    section.add "Version", valid_604063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604064 = header.getOrDefault("X-Amz-Date")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Date", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Security-Token")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Security-Token", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Content-Sha256", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Algorithm")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Algorithm", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-Signature")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Signature", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-SignedHeaders", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Credential")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Credential", valid_604070
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
  var valid_604071 = formData.getOrDefault("SourceIdentifier")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "SourceIdentifier", valid_604071
  var valid_604072 = formData.getOrDefault("EventCategories")
  valid_604072 = validateParameter(valid_604072, JArray, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "EventCategories", valid_604072
  var valid_604073 = formData.getOrDefault("Marker")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "Marker", valid_604073
  var valid_604074 = formData.getOrDefault("StartTime")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "StartTime", valid_604074
  var valid_604075 = formData.getOrDefault("Duration")
  valid_604075 = validateParameter(valid_604075, JInt, required = false, default = nil)
  if valid_604075 != nil:
    section.add "Duration", valid_604075
  var valid_604076 = formData.getOrDefault("Filters")
  valid_604076 = validateParameter(valid_604076, JArray, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "Filters", valid_604076
  var valid_604077 = formData.getOrDefault("EndTime")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "EndTime", valid_604077
  var valid_604078 = formData.getOrDefault("MaxRecords")
  valid_604078 = validateParameter(valid_604078, JInt, required = false, default = nil)
  if valid_604078 != nil:
    section.add "MaxRecords", valid_604078
  var valid_604079 = formData.getOrDefault("SourceType")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604079 != nil:
    section.add "SourceType", valid_604079
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604080: Call_PostDescribeEvents_604059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_604080.validator(path, query, header, formData, body)
  let scheme = call_604080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604080.url(scheme.get, call_604080.host, call_604080.base,
                         call_604080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604080, url, valid)

proc call*(call_604081: Call_PostDescribeEvents_604059;
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
  var query_604082 = newJObject()
  var formData_604083 = newJObject()
  add(formData_604083, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604083.add "EventCategories", EventCategories
  add(formData_604083, "Marker", newJString(Marker))
  add(formData_604083, "StartTime", newJString(StartTime))
  add(query_604082, "Action", newJString(Action))
  add(formData_604083, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604083.add "Filters", Filters
  add(formData_604083, "EndTime", newJString(EndTime))
  add(formData_604083, "MaxRecords", newJInt(MaxRecords))
  add(query_604082, "Version", newJString(Version))
  add(formData_604083, "SourceType", newJString(SourceType))
  result = call_604081.call(nil, query_604082, nil, formData_604083, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604059(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604060, base: "/",
    url: url_PostDescribeEvents_604061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604035 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEvents_604037(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604036(path: JsonNode; query: JsonNode;
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
  var valid_604038 = query.getOrDefault("SourceType")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604038 != nil:
    section.add "SourceType", valid_604038
  var valid_604039 = query.getOrDefault("MaxRecords")
  valid_604039 = validateParameter(valid_604039, JInt, required = false, default = nil)
  if valid_604039 != nil:
    section.add "MaxRecords", valid_604039
  var valid_604040 = query.getOrDefault("StartTime")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "StartTime", valid_604040
  var valid_604041 = query.getOrDefault("Filters")
  valid_604041 = validateParameter(valid_604041, JArray, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "Filters", valid_604041
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604042 = query.getOrDefault("Action")
  valid_604042 = validateParameter(valid_604042, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604042 != nil:
    section.add "Action", valid_604042
  var valid_604043 = query.getOrDefault("SourceIdentifier")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "SourceIdentifier", valid_604043
  var valid_604044 = query.getOrDefault("Marker")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "Marker", valid_604044
  var valid_604045 = query.getOrDefault("EventCategories")
  valid_604045 = validateParameter(valid_604045, JArray, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "EventCategories", valid_604045
  var valid_604046 = query.getOrDefault("Duration")
  valid_604046 = validateParameter(valid_604046, JInt, required = false, default = nil)
  if valid_604046 != nil:
    section.add "Duration", valid_604046
  var valid_604047 = query.getOrDefault("EndTime")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "EndTime", valid_604047
  var valid_604048 = query.getOrDefault("Version")
  valid_604048 = validateParameter(valid_604048, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604048 != nil:
    section.add "Version", valid_604048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604049 = header.getOrDefault("X-Amz-Date")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Date", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Security-Token")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Security-Token", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Content-Sha256", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Algorithm")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Algorithm", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-Signature")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Signature", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-SignedHeaders", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Credential")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Credential", valid_604055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604056: Call_GetDescribeEvents_604035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_604056.validator(path, query, header, formData, body)
  let scheme = call_604056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604056.url(scheme.get, call_604056.host, call_604056.base,
                         call_604056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604056, url, valid)

proc call*(call_604057: Call_GetDescribeEvents_604035;
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
  var query_604058 = newJObject()
  add(query_604058, "SourceType", newJString(SourceType))
  add(query_604058, "MaxRecords", newJInt(MaxRecords))
  add(query_604058, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_604058.add "Filters", Filters
  add(query_604058, "Action", newJString(Action))
  add(query_604058, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604058, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604058.add "EventCategories", EventCategories
  add(query_604058, "Duration", newJInt(Duration))
  add(query_604058, "EndTime", newJString(EndTime))
  add(query_604058, "Version", newJString(Version))
  result = call_604057.call(nil, query_604058, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604035(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604036,
    base: "/", url: url_GetDescribeEvents_604037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604107 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOrderableDBInstanceOptions_604109(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604108(path: JsonNode;
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
  var valid_604110 = query.getOrDefault("Action")
  valid_604110 = validateParameter(valid_604110, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604110 != nil:
    section.add "Action", valid_604110
  var valid_604111 = query.getOrDefault("Version")
  valid_604111 = validateParameter(valid_604111, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604111 != nil:
    section.add "Version", valid_604111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604112 = header.getOrDefault("X-Amz-Date")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Date", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Security-Token")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Security-Token", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Content-Sha256", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Algorithm")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Algorithm", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Signature")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Signature", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-SignedHeaders", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Credential")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Credential", valid_604118
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
  var valid_604119 = formData.getOrDefault("Engine")
  valid_604119 = validateParameter(valid_604119, JString, required = true,
                                 default = nil)
  if valid_604119 != nil:
    section.add "Engine", valid_604119
  var valid_604120 = formData.getOrDefault("Marker")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "Marker", valid_604120
  var valid_604121 = formData.getOrDefault("Vpc")
  valid_604121 = validateParameter(valid_604121, JBool, required = false, default = nil)
  if valid_604121 != nil:
    section.add "Vpc", valid_604121
  var valid_604122 = formData.getOrDefault("DBInstanceClass")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "DBInstanceClass", valid_604122
  var valid_604123 = formData.getOrDefault("Filters")
  valid_604123 = validateParameter(valid_604123, JArray, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "Filters", valid_604123
  var valid_604124 = formData.getOrDefault("LicenseModel")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "LicenseModel", valid_604124
  var valid_604125 = formData.getOrDefault("MaxRecords")
  valid_604125 = validateParameter(valid_604125, JInt, required = false, default = nil)
  if valid_604125 != nil:
    section.add "MaxRecords", valid_604125
  var valid_604126 = formData.getOrDefault("EngineVersion")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "EngineVersion", valid_604126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604127: Call_PostDescribeOrderableDBInstanceOptions_604107;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_604127.validator(path, query, header, formData, body)
  let scheme = call_604127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604127.url(scheme.get, call_604127.host, call_604127.base,
                         call_604127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604127, url, valid)

proc call*(call_604128: Call_PostDescribeOrderableDBInstanceOptions_604107;
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
  var query_604129 = newJObject()
  var formData_604130 = newJObject()
  add(formData_604130, "Engine", newJString(Engine))
  add(formData_604130, "Marker", newJString(Marker))
  add(query_604129, "Action", newJString(Action))
  add(formData_604130, "Vpc", newJBool(Vpc))
  add(formData_604130, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604130.add "Filters", Filters
  add(formData_604130, "LicenseModel", newJString(LicenseModel))
  add(formData_604130, "MaxRecords", newJInt(MaxRecords))
  add(formData_604130, "EngineVersion", newJString(EngineVersion))
  add(query_604129, "Version", newJString(Version))
  result = call_604128.call(nil, query_604129, nil, formData_604130, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604107(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604108, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604084 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOrderableDBInstanceOptions_604086(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604085(path: JsonNode;
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
  var valid_604087 = query.getOrDefault("Engine")
  valid_604087 = validateParameter(valid_604087, JString, required = true,
                                 default = nil)
  if valid_604087 != nil:
    section.add "Engine", valid_604087
  var valid_604088 = query.getOrDefault("MaxRecords")
  valid_604088 = validateParameter(valid_604088, JInt, required = false, default = nil)
  if valid_604088 != nil:
    section.add "MaxRecords", valid_604088
  var valid_604089 = query.getOrDefault("Filters")
  valid_604089 = validateParameter(valid_604089, JArray, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "Filters", valid_604089
  var valid_604090 = query.getOrDefault("LicenseModel")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "LicenseModel", valid_604090
  var valid_604091 = query.getOrDefault("Vpc")
  valid_604091 = validateParameter(valid_604091, JBool, required = false, default = nil)
  if valid_604091 != nil:
    section.add "Vpc", valid_604091
  var valid_604092 = query.getOrDefault("DBInstanceClass")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "DBInstanceClass", valid_604092
  var valid_604093 = query.getOrDefault("Action")
  valid_604093 = validateParameter(valid_604093, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604093 != nil:
    section.add "Action", valid_604093
  var valid_604094 = query.getOrDefault("Marker")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "Marker", valid_604094
  var valid_604095 = query.getOrDefault("EngineVersion")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "EngineVersion", valid_604095
  var valid_604096 = query.getOrDefault("Version")
  valid_604096 = validateParameter(valid_604096, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604096 != nil:
    section.add "Version", valid_604096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604097 = header.getOrDefault("X-Amz-Date")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Date", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Security-Token")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Security-Token", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Content-Sha256", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Algorithm")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Algorithm", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Signature")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Signature", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-SignedHeaders", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Credential")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Credential", valid_604103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604104: Call_GetDescribeOrderableDBInstanceOptions_604084;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_604104.validator(path, query, header, formData, body)
  let scheme = call_604104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604104.url(scheme.get, call_604104.host, call_604104.base,
                         call_604104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604104, url, valid)

proc call*(call_604105: Call_GetDescribeOrderableDBInstanceOptions_604084;
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
  var query_604106 = newJObject()
  add(query_604106, "Engine", newJString(Engine))
  add(query_604106, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604106.add "Filters", Filters
  add(query_604106, "LicenseModel", newJString(LicenseModel))
  add(query_604106, "Vpc", newJBool(Vpc))
  add(query_604106, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604106, "Action", newJString(Action))
  add(query_604106, "Marker", newJString(Marker))
  add(query_604106, "EngineVersion", newJString(EngineVersion))
  add(query_604106, "Version", newJString(Version))
  result = call_604105.call(nil, query_604106, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604084(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604085, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_604150 = ref object of OpenApiRestCall_602450
proc url_PostDescribePendingMaintenanceActions_604152(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_604151(path: JsonNode;
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
  var valid_604153 = query.getOrDefault("Action")
  valid_604153 = validateParameter(valid_604153, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
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
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_604162 = formData.getOrDefault("Marker")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "Marker", valid_604162
  var valid_604163 = formData.getOrDefault("ResourceIdentifier")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "ResourceIdentifier", valid_604163
  var valid_604164 = formData.getOrDefault("Filters")
  valid_604164 = validateParameter(valid_604164, JArray, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "Filters", valid_604164
  var valid_604165 = formData.getOrDefault("MaxRecords")
  valid_604165 = validateParameter(valid_604165, JInt, required = false, default = nil)
  if valid_604165 != nil:
    section.add "MaxRecords", valid_604165
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604166: Call_PostDescribePendingMaintenanceActions_604150;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_604166.validator(path, query, header, formData, body)
  let scheme = call_604166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604166.url(scheme.get, call_604166.host, call_604166.base,
                         call_604166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604166, url, valid)

proc call*(call_604167: Call_PostDescribePendingMaintenanceActions_604150;
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
  var query_604168 = newJObject()
  var formData_604169 = newJObject()
  add(formData_604169, "Marker", newJString(Marker))
  add(query_604168, "Action", newJString(Action))
  add(formData_604169, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_604169.add "Filters", Filters
  add(formData_604169, "MaxRecords", newJInt(MaxRecords))
  add(query_604168, "Version", newJString(Version))
  result = call_604167.call(nil, query_604168, nil, formData_604169, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_604150(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_604151, base: "/",
    url: url_PostDescribePendingMaintenanceActions_604152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_604131 = ref object of OpenApiRestCall_602450
proc url_GetDescribePendingMaintenanceActions_604133(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_604132(path: JsonNode;
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
  var valid_604134 = query.getOrDefault("MaxRecords")
  valid_604134 = validateParameter(valid_604134, JInt, required = false, default = nil)
  if valid_604134 != nil:
    section.add "MaxRecords", valid_604134
  var valid_604135 = query.getOrDefault("Filters")
  valid_604135 = validateParameter(valid_604135, JArray, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "Filters", valid_604135
  var valid_604136 = query.getOrDefault("ResourceIdentifier")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "ResourceIdentifier", valid_604136
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604137 = query.getOrDefault("Action")
  valid_604137 = validateParameter(valid_604137, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_604137 != nil:
    section.add "Action", valid_604137
  var valid_604138 = query.getOrDefault("Marker")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "Marker", valid_604138
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

proc call*(call_604147: Call_GetDescribePendingMaintenanceActions_604131;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_604147.validator(path, query, header, formData, body)
  let scheme = call_604147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604147.url(scheme.get, call_604147.host, call_604147.base,
                         call_604147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604147, url, valid)

proc call*(call_604148: Call_GetDescribePendingMaintenanceActions_604131;
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
  var query_604149 = newJObject()
  add(query_604149, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604149.add "Filters", Filters
  add(query_604149, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_604149, "Action", newJString(Action))
  add(query_604149, "Marker", newJString(Marker))
  add(query_604149, "Version", newJString(Version))
  result = call_604148.call(nil, query_604149, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_604131(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_604132, base: "/",
    url: url_GetDescribePendingMaintenanceActions_604133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_604187 = ref object of OpenApiRestCall_602450
proc url_PostFailoverDBCluster_604189(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostFailoverDBCluster_604188(path: JsonNode; query: JsonNode;
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
  var valid_604190 = query.getOrDefault("Action")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_604190 != nil:
    section.add "Action", valid_604190
  var valid_604191 = query.getOrDefault("Version")
  valid_604191 = validateParameter(valid_604191, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604191 != nil:
    section.add "Version", valid_604191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604192 = header.getOrDefault("X-Amz-Date")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Date", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Security-Token")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Security-Token", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Content-Sha256", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Algorithm")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Algorithm", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Signature")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Signature", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-SignedHeaders", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Credential")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Credential", valid_604198
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_604199 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604199
  var valid_604200 = formData.getOrDefault("DBClusterIdentifier")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "DBClusterIdentifier", valid_604200
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604201: Call_PostFailoverDBCluster_604187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_604201.validator(path, query, header, formData, body)
  let scheme = call_604201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604201.url(scheme.get, call_604201.host, call_604201.base,
                         call_604201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604201, url, valid)

proc call*(call_604202: Call_PostFailoverDBCluster_604187;
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
  var query_604203 = newJObject()
  var formData_604204 = newJObject()
  add(query_604203, "Action", newJString(Action))
  add(formData_604204, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_604204, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604203, "Version", newJString(Version))
  result = call_604202.call(nil, query_604203, nil, formData_604204, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_604187(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_604188, base: "/",
    url: url_PostFailoverDBCluster_604189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_604170 = ref object of OpenApiRestCall_602450
proc url_GetFailoverDBCluster_604172(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFailoverDBCluster_604171(path: JsonNode; query: JsonNode;
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
  var valid_604173 = query.getOrDefault("DBClusterIdentifier")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "DBClusterIdentifier", valid_604173
  var valid_604174 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604174
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604175 = query.getOrDefault("Action")
  valid_604175 = validateParameter(valid_604175, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_604175 != nil:
    section.add "Action", valid_604175
  var valid_604176 = query.getOrDefault("Version")
  valid_604176 = validateParameter(valid_604176, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604176 != nil:
    section.add "Version", valid_604176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604177 = header.getOrDefault("X-Amz-Date")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Date", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Security-Token")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Security-Token", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Content-Sha256", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Algorithm")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Algorithm", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Signature")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Signature", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-SignedHeaders", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Credential")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Credential", valid_604183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604184: Call_GetFailoverDBCluster_604170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_604184.validator(path, query, header, formData, body)
  let scheme = call_604184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604184.url(scheme.get, call_604184.host, call_604184.base,
                         call_604184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604184, url, valid)

proc call*(call_604185: Call_GetFailoverDBCluster_604170;
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
  var query_604186 = newJObject()
  add(query_604186, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604186, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604186, "Action", newJString(Action))
  add(query_604186, "Version", newJString(Version))
  result = call_604185.call(nil, query_604186, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_604170(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_604171, base: "/",
    url: url_GetFailoverDBCluster_604172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604222 = ref object of OpenApiRestCall_602450
proc url_PostListTagsForResource_604224(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604223(path: JsonNode; query: JsonNode;
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
  var valid_604225 = query.getOrDefault("Action")
  valid_604225 = validateParameter(valid_604225, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604225 != nil:
    section.add "Action", valid_604225
  var valid_604226 = query.getOrDefault("Version")
  valid_604226 = validateParameter(valid_604226, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604226 != nil:
    section.add "Version", valid_604226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604227 = header.getOrDefault("X-Amz-Date")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Date", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Security-Token")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Security-Token", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Content-Sha256", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Algorithm")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Algorithm", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Signature")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Signature", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-SignedHeaders", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Credential")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Credential", valid_604233
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_604234 = formData.getOrDefault("Filters")
  valid_604234 = validateParameter(valid_604234, JArray, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "Filters", valid_604234
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604235 = formData.getOrDefault("ResourceName")
  valid_604235 = validateParameter(valid_604235, JString, required = true,
                                 default = nil)
  if valid_604235 != nil:
    section.add "ResourceName", valid_604235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604236: Call_PostListTagsForResource_604222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_604236.validator(path, query, header, formData, body)
  let scheme = call_604236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604236.url(scheme.get, call_604236.host, call_604236.base,
                         call_604236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604236, url, valid)

proc call*(call_604237: Call_PostListTagsForResource_604222; ResourceName: string;
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
  var query_604238 = newJObject()
  var formData_604239 = newJObject()
  add(query_604238, "Action", newJString(Action))
  if Filters != nil:
    formData_604239.add "Filters", Filters
  add(formData_604239, "ResourceName", newJString(ResourceName))
  add(query_604238, "Version", newJString(Version))
  result = call_604237.call(nil, query_604238, nil, formData_604239, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604222(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604223, base: "/",
    url: url_PostListTagsForResource_604224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604205 = ref object of OpenApiRestCall_602450
proc url_GetListTagsForResource_604207(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604206(path: JsonNode; query: JsonNode;
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
  var valid_604208 = query.getOrDefault("Filters")
  valid_604208 = validateParameter(valid_604208, JArray, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "Filters", valid_604208
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604209 = query.getOrDefault("ResourceName")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = nil)
  if valid_604209 != nil:
    section.add "ResourceName", valid_604209
  var valid_604210 = query.getOrDefault("Action")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604210 != nil:
    section.add "Action", valid_604210
  var valid_604211 = query.getOrDefault("Version")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604211 != nil:
    section.add "Version", valid_604211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604212 = header.getOrDefault("X-Amz-Date")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Date", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Security-Token")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Security-Token", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Content-Sha256", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Algorithm", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Signature")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Signature", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-SignedHeaders", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Credential")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Credential", valid_604218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604219: Call_GetListTagsForResource_604205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_604219.validator(path, query, header, formData, body)
  let scheme = call_604219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604219.url(scheme.get, call_604219.host, call_604219.base,
                         call_604219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604219, url, valid)

proc call*(call_604220: Call_GetListTagsForResource_604205; ResourceName: string;
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
  var query_604221 = newJObject()
  if Filters != nil:
    query_604221.add "Filters", Filters
  add(query_604221, "ResourceName", newJString(ResourceName))
  add(query_604221, "Action", newJString(Action))
  add(query_604221, "Version", newJString(Version))
  result = call_604220.call(nil, query_604221, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604205(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604206, base: "/",
    url: url_GetListTagsForResource_604207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_604269 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBCluster_604271(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBCluster_604270(path: JsonNode; query: JsonNode;
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
  var valid_604272 = query.getOrDefault("Action")
  valid_604272 = validateParameter(valid_604272, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_604272 != nil:
    section.add "Action", valid_604272
  var valid_604273 = query.getOrDefault("Version")
  valid_604273 = validateParameter(valid_604273, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604273 != nil:
    section.add "Version", valid_604273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604274 = header.getOrDefault("X-Amz-Date")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Date", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Security-Token")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Security-Token", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-Content-Sha256", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Algorithm")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Algorithm", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Signature")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Signature", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-SignedHeaders", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Credential")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Credential", valid_604280
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  var valid_604281 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_604281 = validateParameter(valid_604281, JArray, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_604281
  var valid_604282 = formData.getOrDefault("ApplyImmediately")
  valid_604282 = validateParameter(valid_604282, JBool, required = false, default = nil)
  if valid_604282 != nil:
    section.add "ApplyImmediately", valid_604282
  var valid_604283 = formData.getOrDefault("Port")
  valid_604283 = validateParameter(valid_604283, JInt, required = false, default = nil)
  if valid_604283 != nil:
    section.add "Port", valid_604283
  var valid_604284 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604284 = validateParameter(valid_604284, JArray, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "VpcSecurityGroupIds", valid_604284
  var valid_604285 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604285 = validateParameter(valid_604285, JInt, required = false, default = nil)
  if valid_604285 != nil:
    section.add "BackupRetentionPeriod", valid_604285
  var valid_604286 = formData.getOrDefault("MasterUserPassword")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "MasterUserPassword", valid_604286
  var valid_604287 = formData.getOrDefault("DeletionProtection")
  valid_604287 = validateParameter(valid_604287, JBool, required = false, default = nil)
  if valid_604287 != nil:
    section.add "DeletionProtection", valid_604287
  var valid_604288 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "NewDBClusterIdentifier", valid_604288
  var valid_604289 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_604289 = validateParameter(valid_604289, JArray, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_604289
  var valid_604290 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "DBClusterParameterGroupName", valid_604290
  var valid_604291 = formData.getOrDefault("PreferredBackupWindow")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "PreferredBackupWindow", valid_604291
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604292 = formData.getOrDefault("DBClusterIdentifier")
  valid_604292 = validateParameter(valid_604292, JString, required = true,
                                 default = nil)
  if valid_604292 != nil:
    section.add "DBClusterIdentifier", valid_604292
  var valid_604293 = formData.getOrDefault("EngineVersion")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "EngineVersion", valid_604293
  var valid_604294 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "PreferredMaintenanceWindow", valid_604294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604295: Call_PostModifyDBCluster_604269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_604295.validator(path, query, header, formData, body)
  let scheme = call_604295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604295.url(scheme.get, call_604295.host, call_604295.base,
                         call_604295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604295, url, valid)

proc call*(call_604296: Call_PostModifyDBCluster_604269;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  var query_604297 = newJObject()
  var formData_604298 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_604298.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_604298, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604298, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_604298.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604298, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604298, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604298, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604298, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_604298.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_604297, "Action", newJString(Action))
  add(formData_604298, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_604298, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604298, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_604298, "EngineVersion", newJString(EngineVersion))
  add(query_604297, "Version", newJString(Version))
  add(formData_604298, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_604296.call(nil, query_604297, nil, formData_604298, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_604269(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_604270, base: "/",
    url: url_PostModifyDBCluster_604271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_604240 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBCluster_604242(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBCluster_604241(path: JsonNode; query: JsonNode;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  var valid_604243 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "PreferredMaintenanceWindow", valid_604243
  var valid_604244 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "DBClusterParameterGroupName", valid_604244
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604245 = query.getOrDefault("DBClusterIdentifier")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = nil)
  if valid_604245 != nil:
    section.add "DBClusterIdentifier", valid_604245
  var valid_604246 = query.getOrDefault("MasterUserPassword")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "MasterUserPassword", valid_604246
  var valid_604247 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_604247 = validateParameter(valid_604247, JArray, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_604247
  var valid_604248 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604248 = validateParameter(valid_604248, JArray, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "VpcSecurityGroupIds", valid_604248
  var valid_604249 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_604249 = validateParameter(valid_604249, JArray, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_604249
  var valid_604250 = query.getOrDefault("BackupRetentionPeriod")
  valid_604250 = validateParameter(valid_604250, JInt, required = false, default = nil)
  if valid_604250 != nil:
    section.add "BackupRetentionPeriod", valid_604250
  var valid_604251 = query.getOrDefault("NewDBClusterIdentifier")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "NewDBClusterIdentifier", valid_604251
  var valid_604252 = query.getOrDefault("DeletionProtection")
  valid_604252 = validateParameter(valid_604252, JBool, required = false, default = nil)
  if valid_604252 != nil:
    section.add "DeletionProtection", valid_604252
  var valid_604253 = query.getOrDefault("Action")
  valid_604253 = validateParameter(valid_604253, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_604253 != nil:
    section.add "Action", valid_604253
  var valid_604254 = query.getOrDefault("EngineVersion")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "EngineVersion", valid_604254
  var valid_604255 = query.getOrDefault("Port")
  valid_604255 = validateParameter(valid_604255, JInt, required = false, default = nil)
  if valid_604255 != nil:
    section.add "Port", valid_604255
  var valid_604256 = query.getOrDefault("PreferredBackupWindow")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "PreferredBackupWindow", valid_604256
  var valid_604257 = query.getOrDefault("Version")
  valid_604257 = validateParameter(valid_604257, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604257 != nil:
    section.add "Version", valid_604257
  var valid_604258 = query.getOrDefault("ApplyImmediately")
  valid_604258 = validateParameter(valid_604258, JBool, required = false, default = nil)
  if valid_604258 != nil:
    section.add "ApplyImmediately", valid_604258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604259 = header.getOrDefault("X-Amz-Date")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Date", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Security-Token")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Security-Token", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Content-Sha256", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Algorithm")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Algorithm", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Signature")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Signature", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-SignedHeaders", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Credential")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Credential", valid_604265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604266: Call_GetModifyDBCluster_604240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_604266.validator(path, query, header, formData, body)
  let scheme = call_604266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604266.url(scheme.get, call_604266.host, call_604266.base,
                         call_604266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604266, url, valid)

proc call*(call_604267: Call_GetModifyDBCluster_604240;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
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
  var query_604268 = newJObject()
  add(query_604268, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604268, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_604268, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604268, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_604268.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_604268.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_604268.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_604268, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604268, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_604268, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604268, "Action", newJString(Action))
  add(query_604268, "EngineVersion", newJString(EngineVersion))
  add(query_604268, "Port", newJInt(Port))
  add(query_604268, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604268, "Version", newJString(Version))
  add(query_604268, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604267.call(nil, query_604268, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_604240(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_604241,
    base: "/", url: url_GetModifyDBCluster_604242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_604316 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBClusterParameterGroup_604318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_604317(path: JsonNode;
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
  var valid_604319 = query.getOrDefault("Action")
  valid_604319 = validateParameter(valid_604319, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_604319 != nil:
    section.add "Action", valid_604319
  var valid_604320 = query.getOrDefault("Version")
  valid_604320 = validateParameter(valid_604320, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604320 != nil:
    section.add "Version", valid_604320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604321 = header.getOrDefault("X-Amz-Date")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Date", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Security-Token")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Security-Token", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Content-Sha256", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Algorithm")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Algorithm", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Signature")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Signature", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-SignedHeaders", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Credential")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Credential", valid_604327
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_604328 = formData.getOrDefault("Parameters")
  valid_604328 = validateParameter(valid_604328, JArray, required = true, default = nil)
  if valid_604328 != nil:
    section.add "Parameters", valid_604328
  var valid_604329 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604329 = validateParameter(valid_604329, JString, required = true,
                                 default = nil)
  if valid_604329 != nil:
    section.add "DBClusterParameterGroupName", valid_604329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604330: Call_PostModifyDBClusterParameterGroup_604316;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_604330.validator(path, query, header, formData, body)
  let scheme = call_604330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604330.url(scheme.get, call_604330.host, call_604330.base,
                         call_604330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604330, url, valid)

proc call*(call_604331: Call_PostModifyDBClusterParameterGroup_604316;
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
  var query_604332 = newJObject()
  var formData_604333 = newJObject()
  if Parameters != nil:
    formData_604333.add "Parameters", Parameters
  add(query_604332, "Action", newJString(Action))
  add(formData_604333, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_604332, "Version", newJString(Version))
  result = call_604331.call(nil, query_604332, nil, formData_604333, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_604316(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_604317, base: "/",
    url: url_PostModifyDBClusterParameterGroup_604318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_604299 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBClusterParameterGroup_604301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_604300(path: JsonNode;
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
  var valid_604302 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604302 = validateParameter(valid_604302, JString, required = true,
                                 default = nil)
  if valid_604302 != nil:
    section.add "DBClusterParameterGroupName", valid_604302
  var valid_604303 = query.getOrDefault("Parameters")
  valid_604303 = validateParameter(valid_604303, JArray, required = true, default = nil)
  if valid_604303 != nil:
    section.add "Parameters", valid_604303
  var valid_604304 = query.getOrDefault("Action")
  valid_604304 = validateParameter(valid_604304, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_604304 != nil:
    section.add "Action", valid_604304
  var valid_604305 = query.getOrDefault("Version")
  valid_604305 = validateParameter(valid_604305, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604305 != nil:
    section.add "Version", valid_604305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604306 = header.getOrDefault("X-Amz-Date")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-Date", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Security-Token")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Security-Token", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Content-Sha256", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Algorithm")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Algorithm", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Signature")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Signature", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-SignedHeaders", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Credential")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Credential", valid_604312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604313: Call_GetModifyDBClusterParameterGroup_604299;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_604313.validator(path, query, header, formData, body)
  let scheme = call_604313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604313.url(scheme.get, call_604313.host, call_604313.base,
                         call_604313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604313, url, valid)

proc call*(call_604314: Call_GetModifyDBClusterParameterGroup_604299;
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
  var query_604315 = newJObject()
  add(query_604315, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_604315.add "Parameters", Parameters
  add(query_604315, "Action", newJString(Action))
  add(query_604315, "Version", newJString(Version))
  result = call_604314.call(nil, query_604315, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_604299(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_604300, base: "/",
    url: url_GetModifyDBClusterParameterGroup_604301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_604353 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBClusterSnapshotAttribute_604355(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_604354(path: JsonNode;
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
  var valid_604356 = query.getOrDefault("Action")
  valid_604356 = validateParameter(valid_604356, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_604356 != nil:
    section.add "Action", valid_604356
  var valid_604357 = query.getOrDefault("Version")
  valid_604357 = validateParameter(valid_604357, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604357 != nil:
    section.add "Version", valid_604357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604358 = header.getOrDefault("X-Amz-Date")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Date", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Security-Token")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Security-Token", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Content-Sha256", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Algorithm")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Algorithm", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-Signature")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-Signature", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-SignedHeaders", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Credential")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Credential", valid_604364
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
  var valid_604365 = formData.getOrDefault("AttributeName")
  valid_604365 = validateParameter(valid_604365, JString, required = true,
                                 default = nil)
  if valid_604365 != nil:
    section.add "AttributeName", valid_604365
  var valid_604366 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_604366 = validateParameter(valid_604366, JString, required = true,
                                 default = nil)
  if valid_604366 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_604366
  var valid_604367 = formData.getOrDefault("ValuesToRemove")
  valid_604367 = validateParameter(valid_604367, JArray, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "ValuesToRemove", valid_604367
  var valid_604368 = formData.getOrDefault("ValuesToAdd")
  valid_604368 = validateParameter(valid_604368, JArray, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "ValuesToAdd", valid_604368
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604369: Call_PostModifyDBClusterSnapshotAttribute_604353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_604369.validator(path, query, header, formData, body)
  let scheme = call_604369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604369.url(scheme.get, call_604369.host, call_604369.base,
                         call_604369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604369, url, valid)

proc call*(call_604370: Call_PostModifyDBClusterSnapshotAttribute_604353;
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
  var query_604371 = newJObject()
  var formData_604372 = newJObject()
  add(formData_604372, "AttributeName", newJString(AttributeName))
  add(formData_604372, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_604371, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_604372.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_604372.add "ValuesToAdd", ValuesToAdd
  add(query_604371, "Version", newJString(Version))
  result = call_604370.call(nil, query_604371, nil, formData_604372, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_604353(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_604354, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_604355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_604334 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBClusterSnapshotAttribute_604336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_604335(path: JsonNode;
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
  var valid_604337 = query.getOrDefault("AttributeName")
  valid_604337 = validateParameter(valid_604337, JString, required = true,
                                 default = nil)
  if valid_604337 != nil:
    section.add "AttributeName", valid_604337
  var valid_604338 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_604338 = validateParameter(valid_604338, JString, required = true,
                                 default = nil)
  if valid_604338 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_604338
  var valid_604339 = query.getOrDefault("ValuesToAdd")
  valid_604339 = validateParameter(valid_604339, JArray, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "ValuesToAdd", valid_604339
  var valid_604340 = query.getOrDefault("Action")
  valid_604340 = validateParameter(valid_604340, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_604340 != nil:
    section.add "Action", valid_604340
  var valid_604341 = query.getOrDefault("ValuesToRemove")
  valid_604341 = validateParameter(valid_604341, JArray, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "ValuesToRemove", valid_604341
  var valid_604342 = query.getOrDefault("Version")
  valid_604342 = validateParameter(valid_604342, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604342 != nil:
    section.add "Version", valid_604342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604343 = header.getOrDefault("X-Amz-Date")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Date", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-Security-Token")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Security-Token", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Content-Sha256", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Algorithm")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Algorithm", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Signature")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Signature", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-SignedHeaders", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Credential")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Credential", valid_604349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604350: Call_GetModifyDBClusterSnapshotAttribute_604334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_604350.validator(path, query, header, formData, body)
  let scheme = call_604350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604350.url(scheme.get, call_604350.host, call_604350.base,
                         call_604350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604350, url, valid)

proc call*(call_604351: Call_GetModifyDBClusterSnapshotAttribute_604334;
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
  var query_604352 = newJObject()
  add(query_604352, "AttributeName", newJString(AttributeName))
  add(query_604352, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_604352.add "ValuesToAdd", ValuesToAdd
  add(query_604352, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_604352.add "ValuesToRemove", ValuesToRemove
  add(query_604352, "Version", newJString(Version))
  result = call_604351.call(nil, query_604352, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_604334(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_604335, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_604336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604396 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBInstance_604398(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_604397(path: JsonNode; query: JsonNode;
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
  var valid_604399 = query.getOrDefault("Action")
  valid_604399 = validateParameter(valid_604399, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604399 != nil:
    section.add "Action", valid_604399
  var valid_604400 = query.getOrDefault("Version")
  valid_604400 = validateParameter(valid_604400, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604400 != nil:
    section.add "Version", valid_604400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604401 = header.getOrDefault("X-Amz-Date")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Date", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Security-Token")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Security-Token", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Content-Sha256", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Algorithm")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Algorithm", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Signature")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Signature", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-SignedHeaders", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Credential")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Credential", valid_604407
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
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
  var valid_604408 = formData.getOrDefault("ApplyImmediately")
  valid_604408 = validateParameter(valid_604408, JBool, required = false, default = nil)
  if valid_604408 != nil:
    section.add "ApplyImmediately", valid_604408
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604409 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604409 = validateParameter(valid_604409, JString, required = true,
                                 default = nil)
  if valid_604409 != nil:
    section.add "DBInstanceIdentifier", valid_604409
  var valid_604410 = formData.getOrDefault("CACertificateIdentifier")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "CACertificateIdentifier", valid_604410
  var valid_604411 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "NewDBInstanceIdentifier", valid_604411
  var valid_604412 = formData.getOrDefault("PromotionTier")
  valid_604412 = validateParameter(valid_604412, JInt, required = false, default = nil)
  if valid_604412 != nil:
    section.add "PromotionTier", valid_604412
  var valid_604413 = formData.getOrDefault("DBInstanceClass")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "DBInstanceClass", valid_604413
  var valid_604414 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604414 = validateParameter(valid_604414, JBool, required = false, default = nil)
  if valid_604414 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604414
  var valid_604415 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "PreferredMaintenanceWindow", valid_604415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604416: Call_PostModifyDBInstance_604396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_604416.validator(path, query, header, formData, body)
  let scheme = call_604416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604416.url(scheme.get, call_604416.host, call_604416.base,
                         call_604416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604416, url, valid)

proc call*(call_604417: Call_PostModifyDBInstance_604396;
          DBInstanceIdentifier: string; ApplyImmediately: bool = false;
          CACertificateIdentifier: string = "";
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
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
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
  var query_604418 = newJObject()
  var formData_604419 = newJObject()
  add(formData_604419, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604419, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604419, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_604419, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_604418, "Action", newJString(Action))
  add(formData_604419, "PromotionTier", newJInt(PromotionTier))
  add(formData_604419, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604419, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_604418, "Version", newJString(Version))
  add(formData_604419, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_604417.call(nil, query_604418, nil, formData_604419, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604396(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604397, base: "/",
    url: url_PostModifyDBInstance_604398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604373 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBInstance_604375(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_604374(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
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
  var valid_604376 = query.getOrDefault("CACertificateIdentifier")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "CACertificateIdentifier", valid_604376
  var valid_604377 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "PreferredMaintenanceWindow", valid_604377
  var valid_604378 = query.getOrDefault("PromotionTier")
  valid_604378 = validateParameter(valid_604378, JInt, required = false, default = nil)
  if valid_604378 != nil:
    section.add "PromotionTier", valid_604378
  var valid_604379 = query.getOrDefault("DBInstanceClass")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "DBInstanceClass", valid_604379
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604380 = query.getOrDefault("Action")
  valid_604380 = validateParameter(valid_604380, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604380 != nil:
    section.add "Action", valid_604380
  var valid_604381 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "NewDBInstanceIdentifier", valid_604381
  var valid_604382 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604382 = validateParameter(valid_604382, JBool, required = false, default = nil)
  if valid_604382 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604382
  var valid_604383 = query.getOrDefault("Version")
  valid_604383 = validateParameter(valid_604383, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604383 != nil:
    section.add "Version", valid_604383
  var valid_604384 = query.getOrDefault("DBInstanceIdentifier")
  valid_604384 = validateParameter(valid_604384, JString, required = true,
                                 default = nil)
  if valid_604384 != nil:
    section.add "DBInstanceIdentifier", valid_604384
  var valid_604385 = query.getOrDefault("ApplyImmediately")
  valid_604385 = validateParameter(valid_604385, JBool, required = false, default = nil)
  if valid_604385 != nil:
    section.add "ApplyImmediately", valid_604385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604386 = header.getOrDefault("X-Amz-Date")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-Date", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Security-Token")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Security-Token", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Content-Sha256", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Algorithm")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Algorithm", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Signature")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Signature", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-SignedHeaders", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Credential")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Credential", valid_604392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604393: Call_GetModifyDBInstance_604373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_604393.validator(path, query, header, formData, body)
  let scheme = call_604393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604393.url(scheme.get, call_604393.host, call_604393.base,
                         call_604393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604393, url, valid)

proc call*(call_604394: Call_GetModifyDBInstance_604373;
          DBInstanceIdentifier: string; CACertificateIdentifier: string = "";
          PreferredMaintenanceWindow: string = ""; PromotionTier: int = 0;
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
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
  var query_604395 = newJObject()
  add(query_604395, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_604395, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604395, "PromotionTier", newJInt(PromotionTier))
  add(query_604395, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604395, "Action", newJString(Action))
  add(query_604395, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604395, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604395, "Version", newJString(Version))
  add(query_604395, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604395, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604394.call(nil, query_604395, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604373(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604374, base: "/",
    url: url_GetModifyDBInstance_604375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604438 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBSubnetGroup_604440(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_604439(path: JsonNode; query: JsonNode;
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
  var valid_604441 = query.getOrDefault("Action")
  valid_604441 = validateParameter(valid_604441, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604441 != nil:
    section.add "Action", valid_604441
  var valid_604442 = query.getOrDefault("Version")
  valid_604442 = validateParameter(valid_604442, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604442 != nil:
    section.add "Version", valid_604442
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604443 = header.getOrDefault("X-Amz-Date")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Date", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Security-Token")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Security-Token", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Content-Sha256", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-Algorithm")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Algorithm", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Signature")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Signature", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-SignedHeaders", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-Credential")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-Credential", valid_604449
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
  var valid_604450 = formData.getOrDefault("DBSubnetGroupName")
  valid_604450 = validateParameter(valid_604450, JString, required = true,
                                 default = nil)
  if valid_604450 != nil:
    section.add "DBSubnetGroupName", valid_604450
  var valid_604451 = formData.getOrDefault("SubnetIds")
  valid_604451 = validateParameter(valid_604451, JArray, required = true, default = nil)
  if valid_604451 != nil:
    section.add "SubnetIds", valid_604451
  var valid_604452 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "DBSubnetGroupDescription", valid_604452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604453: Call_PostModifyDBSubnetGroup_604438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_604453.validator(path, query, header, formData, body)
  let scheme = call_604453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604453.url(scheme.get, call_604453.host, call_604453.base,
                         call_604453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604453, url, valid)

proc call*(call_604454: Call_PostModifyDBSubnetGroup_604438;
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
  var query_604455 = newJObject()
  var formData_604456 = newJObject()
  add(formData_604456, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604456.add "SubnetIds", SubnetIds
  add(query_604455, "Action", newJString(Action))
  add(formData_604456, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604455, "Version", newJString(Version))
  result = call_604454.call(nil, query_604455, nil, formData_604456, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604438(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604439, base: "/",
    url: url_PostModifyDBSubnetGroup_604440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604420 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBSubnetGroup_604422(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_604421(path: JsonNode; query: JsonNode;
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
  var valid_604423 = query.getOrDefault("Action")
  valid_604423 = validateParameter(valid_604423, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604423 != nil:
    section.add "Action", valid_604423
  var valid_604424 = query.getOrDefault("DBSubnetGroupName")
  valid_604424 = validateParameter(valid_604424, JString, required = true,
                                 default = nil)
  if valid_604424 != nil:
    section.add "DBSubnetGroupName", valid_604424
  var valid_604425 = query.getOrDefault("SubnetIds")
  valid_604425 = validateParameter(valid_604425, JArray, required = true, default = nil)
  if valid_604425 != nil:
    section.add "SubnetIds", valid_604425
  var valid_604426 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "DBSubnetGroupDescription", valid_604426
  var valid_604427 = query.getOrDefault("Version")
  valid_604427 = validateParameter(valid_604427, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604427 != nil:
    section.add "Version", valid_604427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604428 = header.getOrDefault("X-Amz-Date")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Date", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Security-Token")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Security-Token", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Content-Sha256", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Algorithm")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Algorithm", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Signature")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Signature", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-SignedHeaders", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-Credential")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-Credential", valid_604434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604435: Call_GetModifyDBSubnetGroup_604420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_604435.validator(path, query, header, formData, body)
  let scheme = call_604435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604435.url(scheme.get, call_604435.host, call_604435.base,
                         call_604435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604435, url, valid)

proc call*(call_604436: Call_GetModifyDBSubnetGroup_604420;
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
  var query_604437 = newJObject()
  add(query_604437, "Action", newJString(Action))
  add(query_604437, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604437.add "SubnetIds", SubnetIds
  add(query_604437, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604437, "Version", newJString(Version))
  result = call_604436.call(nil, query_604437, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604420(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604421, base: "/",
    url: url_GetModifyDBSubnetGroup_604422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604474 = ref object of OpenApiRestCall_602450
proc url_PostRebootDBInstance_604476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_604475(path: JsonNode; query: JsonNode;
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
  var valid_604477 = query.getOrDefault("Action")
  valid_604477 = validateParameter(valid_604477, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604477 != nil:
    section.add "Action", valid_604477
  var valid_604478 = query.getOrDefault("Version")
  valid_604478 = validateParameter(valid_604478, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604478 != nil:
    section.add "Version", valid_604478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604479 = header.getOrDefault("X-Amz-Date")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Date", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Security-Token")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Security-Token", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Content-Sha256", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Algorithm")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Algorithm", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Signature")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Signature", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-SignedHeaders", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Credential")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Credential", valid_604485
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604486 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604486 = validateParameter(valid_604486, JString, required = true,
                                 default = nil)
  if valid_604486 != nil:
    section.add "DBInstanceIdentifier", valid_604486
  var valid_604487 = formData.getOrDefault("ForceFailover")
  valid_604487 = validateParameter(valid_604487, JBool, required = false, default = nil)
  if valid_604487 != nil:
    section.add "ForceFailover", valid_604487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604488: Call_PostRebootDBInstance_604474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_604488.validator(path, query, header, formData, body)
  let scheme = call_604488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604488.url(scheme.get, call_604488.host, call_604488.base,
                         call_604488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604488, url, valid)

proc call*(call_604489: Call_PostRebootDBInstance_604474;
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
  var query_604490 = newJObject()
  var formData_604491 = newJObject()
  add(formData_604491, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604490, "Action", newJString(Action))
  add(formData_604491, "ForceFailover", newJBool(ForceFailover))
  add(query_604490, "Version", newJString(Version))
  result = call_604489.call(nil, query_604490, nil, formData_604491, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604474(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604475, base: "/",
    url: url_PostRebootDBInstance_604476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604457 = ref object of OpenApiRestCall_602450
proc url_GetRebootDBInstance_604459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_604458(path: JsonNode; query: JsonNode;
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
  var valid_604460 = query.getOrDefault("Action")
  valid_604460 = validateParameter(valid_604460, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604460 != nil:
    section.add "Action", valid_604460
  var valid_604461 = query.getOrDefault("ForceFailover")
  valid_604461 = validateParameter(valid_604461, JBool, required = false, default = nil)
  if valid_604461 != nil:
    section.add "ForceFailover", valid_604461
  var valid_604462 = query.getOrDefault("Version")
  valid_604462 = validateParameter(valid_604462, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604462 != nil:
    section.add "Version", valid_604462
  var valid_604463 = query.getOrDefault("DBInstanceIdentifier")
  valid_604463 = validateParameter(valid_604463, JString, required = true,
                                 default = nil)
  if valid_604463 != nil:
    section.add "DBInstanceIdentifier", valid_604463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604464 = header.getOrDefault("X-Amz-Date")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-Date", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Security-Token")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Security-Token", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Content-Sha256", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Algorithm")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Algorithm", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-Signature")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Signature", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-SignedHeaders", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Credential")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Credential", valid_604470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604471: Call_GetRebootDBInstance_604457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_604471.validator(path, query, header, formData, body)
  let scheme = call_604471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604471.url(scheme.get, call_604471.host, call_604471.base,
                         call_604471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604471, url, valid)

proc call*(call_604472: Call_GetRebootDBInstance_604457;
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
  var query_604473 = newJObject()
  add(query_604473, "Action", newJString(Action))
  add(query_604473, "ForceFailover", newJBool(ForceFailover))
  add(query_604473, "Version", newJString(Version))
  add(query_604473, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604472.call(nil, query_604473, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604457(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604458, base: "/",
    url: url_GetRebootDBInstance_604459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604509 = ref object of OpenApiRestCall_602450
proc url_PostRemoveTagsFromResource_604511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_604510(path: JsonNode; query: JsonNode;
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
  var valid_604512 = query.getOrDefault("Action")
  valid_604512 = validateParameter(valid_604512, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604512 != nil:
    section.add "Action", valid_604512
  var valid_604513 = query.getOrDefault("Version")
  valid_604513 = validateParameter(valid_604513, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604513 != nil:
    section.add "Version", valid_604513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604514 = header.getOrDefault("X-Amz-Date")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Date", valid_604514
  var valid_604515 = header.getOrDefault("X-Amz-Security-Token")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Security-Token", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-Content-Sha256", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Algorithm")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Algorithm", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-Signature")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Signature", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-SignedHeaders", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Credential")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Credential", valid_604520
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604521 = formData.getOrDefault("TagKeys")
  valid_604521 = validateParameter(valid_604521, JArray, required = true, default = nil)
  if valid_604521 != nil:
    section.add "TagKeys", valid_604521
  var valid_604522 = formData.getOrDefault("ResourceName")
  valid_604522 = validateParameter(valid_604522, JString, required = true,
                                 default = nil)
  if valid_604522 != nil:
    section.add "ResourceName", valid_604522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604523: Call_PostRemoveTagsFromResource_604509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_604523.validator(path, query, header, formData, body)
  let scheme = call_604523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604523.url(scheme.get, call_604523.host, call_604523.base,
                         call_604523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604523, url, valid)

proc call*(call_604524: Call_PostRemoveTagsFromResource_604509; TagKeys: JsonNode;
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
  var query_604525 = newJObject()
  var formData_604526 = newJObject()
  add(query_604525, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604526.add "TagKeys", TagKeys
  add(formData_604526, "ResourceName", newJString(ResourceName))
  add(query_604525, "Version", newJString(Version))
  result = call_604524.call(nil, query_604525, nil, formData_604526, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604509(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604510, base: "/",
    url: url_PostRemoveTagsFromResource_604511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604492 = ref object of OpenApiRestCall_602450
proc url_GetRemoveTagsFromResource_604494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_604493(path: JsonNode; query: JsonNode;
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
  var valid_604495 = query.getOrDefault("ResourceName")
  valid_604495 = validateParameter(valid_604495, JString, required = true,
                                 default = nil)
  if valid_604495 != nil:
    section.add "ResourceName", valid_604495
  var valid_604496 = query.getOrDefault("Action")
  valid_604496 = validateParameter(valid_604496, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604496 != nil:
    section.add "Action", valid_604496
  var valid_604497 = query.getOrDefault("TagKeys")
  valid_604497 = validateParameter(valid_604497, JArray, required = true, default = nil)
  if valid_604497 != nil:
    section.add "TagKeys", valid_604497
  var valid_604498 = query.getOrDefault("Version")
  valid_604498 = validateParameter(valid_604498, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604498 != nil:
    section.add "Version", valid_604498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604499 = header.getOrDefault("X-Amz-Date")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Date", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Security-Token")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Security-Token", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Content-Sha256", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Algorithm")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Algorithm", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Signature")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Signature", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-SignedHeaders", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Credential")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Credential", valid_604505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604506: Call_GetRemoveTagsFromResource_604492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_604506.validator(path, query, header, formData, body)
  let scheme = call_604506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604506.url(scheme.get, call_604506.host, call_604506.base,
                         call_604506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604506, url, valid)

proc call*(call_604507: Call_GetRemoveTagsFromResource_604492;
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
  var query_604508 = newJObject()
  add(query_604508, "ResourceName", newJString(ResourceName))
  add(query_604508, "Action", newJString(Action))
  if TagKeys != nil:
    query_604508.add "TagKeys", TagKeys
  add(query_604508, "Version", newJString(Version))
  result = call_604507.call(nil, query_604508, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604492(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604493, base: "/",
    url: url_GetRemoveTagsFromResource_604494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_604545 = ref object of OpenApiRestCall_602450
proc url_PostResetDBClusterParameterGroup_604547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBClusterParameterGroup_604546(path: JsonNode;
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
  var valid_604548 = query.getOrDefault("Action")
  valid_604548 = validateParameter(valid_604548, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_604548 != nil:
    section.add "Action", valid_604548
  var valid_604549 = query.getOrDefault("Version")
  valid_604549 = validateParameter(valid_604549, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604549 != nil:
    section.add "Version", valid_604549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604550 = header.getOrDefault("X-Amz-Date")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Date", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Security-Token")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Security-Token", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Content-Sha256", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Algorithm")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Algorithm", valid_604553
  var valid_604554 = header.getOrDefault("X-Amz-Signature")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-Signature", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-SignedHeaders", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Credential")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Credential", valid_604556
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_604557 = formData.getOrDefault("Parameters")
  valid_604557 = validateParameter(valid_604557, JArray, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "Parameters", valid_604557
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_604558 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604558 = validateParameter(valid_604558, JString, required = true,
                                 default = nil)
  if valid_604558 != nil:
    section.add "DBClusterParameterGroupName", valid_604558
  var valid_604559 = formData.getOrDefault("ResetAllParameters")
  valid_604559 = validateParameter(valid_604559, JBool, required = false, default = nil)
  if valid_604559 != nil:
    section.add "ResetAllParameters", valid_604559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604560: Call_PostResetDBClusterParameterGroup_604545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_604560.validator(path, query, header, formData, body)
  let scheme = call_604560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604560.url(scheme.get, call_604560.host, call_604560.base,
                         call_604560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604560, url, valid)

proc call*(call_604561: Call_PostResetDBClusterParameterGroup_604545;
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
  var query_604562 = newJObject()
  var formData_604563 = newJObject()
  if Parameters != nil:
    formData_604563.add "Parameters", Parameters
  add(query_604562, "Action", newJString(Action))
  add(formData_604563, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_604563, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604562, "Version", newJString(Version))
  result = call_604561.call(nil, query_604562, nil, formData_604563, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_604545(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_604546, base: "/",
    url: url_PostResetDBClusterParameterGroup_604547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_604527 = ref object of OpenApiRestCall_602450
proc url_GetResetDBClusterParameterGroup_604529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBClusterParameterGroup_604528(path: JsonNode;
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
  var valid_604530 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604530 = validateParameter(valid_604530, JString, required = true,
                                 default = nil)
  if valid_604530 != nil:
    section.add "DBClusterParameterGroupName", valid_604530
  var valid_604531 = query.getOrDefault("Parameters")
  valid_604531 = validateParameter(valid_604531, JArray, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "Parameters", valid_604531
  var valid_604532 = query.getOrDefault("Action")
  valid_604532 = validateParameter(valid_604532, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_604532 != nil:
    section.add "Action", valid_604532
  var valid_604533 = query.getOrDefault("ResetAllParameters")
  valid_604533 = validateParameter(valid_604533, JBool, required = false, default = nil)
  if valid_604533 != nil:
    section.add "ResetAllParameters", valid_604533
  var valid_604534 = query.getOrDefault("Version")
  valid_604534 = validateParameter(valid_604534, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604534 != nil:
    section.add "Version", valid_604534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604535 = header.getOrDefault("X-Amz-Date")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Date", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Security-Token")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Security-Token", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Content-Sha256", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Algorithm")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Algorithm", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-Signature")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-Signature", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-SignedHeaders", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Credential")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Credential", valid_604541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604542: Call_GetResetDBClusterParameterGroup_604527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_604542.validator(path, query, header, formData, body)
  let scheme = call_604542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604542.url(scheme.get, call_604542.host, call_604542.base,
                         call_604542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604542, url, valid)

proc call*(call_604543: Call_GetResetDBClusterParameterGroup_604527;
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
  var query_604544 = newJObject()
  add(query_604544, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_604544.add "Parameters", Parameters
  add(query_604544, "Action", newJString(Action))
  add(query_604544, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604544, "Version", newJString(Version))
  result = call_604543.call(nil, query_604544, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_604527(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_604528, base: "/",
    url: url_GetResetDBClusterParameterGroup_604529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_604591 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBClusterFromSnapshot_604593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_604592(path: JsonNode;
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
  var valid_604594 = query.getOrDefault("Action")
  valid_604594 = validateParameter(valid_604594, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_604594 != nil:
    section.add "Action", valid_604594
  var valid_604595 = query.getOrDefault("Version")
  valid_604595 = validateParameter(valid_604595, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604595 != nil:
    section.add "Version", valid_604595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604596 = header.getOrDefault("X-Amz-Date")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-Date", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Security-Token")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Security-Token", valid_604597
  var valid_604598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Content-Sha256", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-Algorithm")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-Algorithm", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Signature")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Signature", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-SignedHeaders", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Credential")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Credential", valid_604602
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
  var valid_604603 = formData.getOrDefault("Port")
  valid_604603 = validateParameter(valid_604603, JInt, required = false, default = nil)
  if valid_604603 != nil:
    section.add "Port", valid_604603
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_604604 = formData.getOrDefault("Engine")
  valid_604604 = validateParameter(valid_604604, JString, required = true,
                                 default = nil)
  if valid_604604 != nil:
    section.add "Engine", valid_604604
  var valid_604605 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604605 = validateParameter(valid_604605, JArray, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "VpcSecurityGroupIds", valid_604605
  var valid_604606 = formData.getOrDefault("Tags")
  valid_604606 = validateParameter(valid_604606, JArray, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "Tags", valid_604606
  var valid_604607 = formData.getOrDefault("DeletionProtection")
  valid_604607 = validateParameter(valid_604607, JBool, required = false, default = nil)
  if valid_604607 != nil:
    section.add "DeletionProtection", valid_604607
  var valid_604608 = formData.getOrDefault("DBSubnetGroupName")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "DBSubnetGroupName", valid_604608
  var valid_604609 = formData.getOrDefault("AvailabilityZones")
  valid_604609 = validateParameter(valid_604609, JArray, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "AvailabilityZones", valid_604609
  var valid_604610 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_604610 = validateParameter(valid_604610, JArray, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604610
  var valid_604611 = formData.getOrDefault("KmsKeyId")
  valid_604611 = validateParameter(valid_604611, JString, required = false,
                                 default = nil)
  if valid_604611 != nil:
    section.add "KmsKeyId", valid_604611
  var valid_604612 = formData.getOrDefault("SnapshotIdentifier")
  valid_604612 = validateParameter(valid_604612, JString, required = true,
                                 default = nil)
  if valid_604612 != nil:
    section.add "SnapshotIdentifier", valid_604612
  var valid_604613 = formData.getOrDefault("DBClusterIdentifier")
  valid_604613 = validateParameter(valid_604613, JString, required = true,
                                 default = nil)
  if valid_604613 != nil:
    section.add "DBClusterIdentifier", valid_604613
  var valid_604614 = formData.getOrDefault("EngineVersion")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "EngineVersion", valid_604614
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604615: Call_PostRestoreDBClusterFromSnapshot_604591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_604615.validator(path, query, header, formData, body)
  let scheme = call_604615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604615.url(scheme.get, call_604615.host, call_604615.base,
                         call_604615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604615, url, valid)

proc call*(call_604616: Call_PostRestoreDBClusterFromSnapshot_604591;
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
  var query_604617 = newJObject()
  var formData_604618 = newJObject()
  add(formData_604618, "Port", newJInt(Port))
  add(formData_604618, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_604618.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_604618.add "Tags", Tags
  add(formData_604618, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604618, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604617, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_604618.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_604618.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_604618, "KmsKeyId", newJString(KmsKeyId))
  add(formData_604618, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_604618, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_604618, "EngineVersion", newJString(EngineVersion))
  add(query_604617, "Version", newJString(Version))
  result = call_604616.call(nil, query_604617, nil, formData_604618, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_604591(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_604592, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_604593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_604564 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBClusterFromSnapshot_604566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_604565(path: JsonNode;
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
  var valid_604567 = query.getOrDefault("Engine")
  valid_604567 = validateParameter(valid_604567, JString, required = true,
                                 default = nil)
  if valid_604567 != nil:
    section.add "Engine", valid_604567
  var valid_604568 = query.getOrDefault("AvailabilityZones")
  valid_604568 = validateParameter(valid_604568, JArray, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "AvailabilityZones", valid_604568
  var valid_604569 = query.getOrDefault("DBClusterIdentifier")
  valid_604569 = validateParameter(valid_604569, JString, required = true,
                                 default = nil)
  if valid_604569 != nil:
    section.add "DBClusterIdentifier", valid_604569
  var valid_604570 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604570 = validateParameter(valid_604570, JArray, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "VpcSecurityGroupIds", valid_604570
  var valid_604571 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_604571 = validateParameter(valid_604571, JArray, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604571
  var valid_604572 = query.getOrDefault("Tags")
  valid_604572 = validateParameter(valid_604572, JArray, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "Tags", valid_604572
  var valid_604573 = query.getOrDefault("DeletionProtection")
  valid_604573 = validateParameter(valid_604573, JBool, required = false, default = nil)
  if valid_604573 != nil:
    section.add "DeletionProtection", valid_604573
  var valid_604574 = query.getOrDefault("Action")
  valid_604574 = validateParameter(valid_604574, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_604574 != nil:
    section.add "Action", valid_604574
  var valid_604575 = query.getOrDefault("DBSubnetGroupName")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "DBSubnetGroupName", valid_604575
  var valid_604576 = query.getOrDefault("KmsKeyId")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "KmsKeyId", valid_604576
  var valid_604577 = query.getOrDefault("EngineVersion")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "EngineVersion", valid_604577
  var valid_604578 = query.getOrDefault("Port")
  valid_604578 = validateParameter(valid_604578, JInt, required = false, default = nil)
  if valid_604578 != nil:
    section.add "Port", valid_604578
  var valid_604579 = query.getOrDefault("SnapshotIdentifier")
  valid_604579 = validateParameter(valid_604579, JString, required = true,
                                 default = nil)
  if valid_604579 != nil:
    section.add "SnapshotIdentifier", valid_604579
  var valid_604580 = query.getOrDefault("Version")
  valid_604580 = validateParameter(valid_604580, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604580 != nil:
    section.add "Version", valid_604580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604581 = header.getOrDefault("X-Amz-Date")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Date", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Security-Token")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Security-Token", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Content-Sha256", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-Algorithm")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Algorithm", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Signature")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Signature", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-SignedHeaders", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Credential")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Credential", valid_604587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604588: Call_GetRestoreDBClusterFromSnapshot_604564;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_604588.validator(path, query, header, formData, body)
  let scheme = call_604588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604588.url(scheme.get, call_604588.host, call_604588.base,
                         call_604588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604588, url, valid)

proc call*(call_604589: Call_GetRestoreDBClusterFromSnapshot_604564;
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
  var query_604590 = newJObject()
  add(query_604590, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_604590.add "AvailabilityZones", AvailabilityZones
  add(query_604590, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_604590.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_604590.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_604590.add "Tags", Tags
  add(query_604590, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604590, "Action", newJString(Action))
  add(query_604590, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604590, "KmsKeyId", newJString(KmsKeyId))
  add(query_604590, "EngineVersion", newJString(EngineVersion))
  add(query_604590, "Port", newJInt(Port))
  add(query_604590, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_604590, "Version", newJString(Version))
  result = call_604589.call(nil, query_604590, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_604564(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_604565, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_604566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_604645 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBClusterToPointInTime_604647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_604646(path: JsonNode;
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
  var valid_604648 = query.getOrDefault("Action")
  valid_604648 = validateParameter(valid_604648, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_604648 != nil:
    section.add "Action", valid_604648
  var valid_604649 = query.getOrDefault("Version")
  valid_604649 = validateParameter(valid_604649, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604649 != nil:
    section.add "Version", valid_604649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604650 = header.getOrDefault("X-Amz-Date")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Date", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-Security-Token")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-Security-Token", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Content-Sha256", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Algorithm")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Algorithm", valid_604653
  var valid_604654 = header.getOrDefault("X-Amz-Signature")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Signature", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-SignedHeaders", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Credential")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Credential", valid_604656
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
  var valid_604657 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_604657 = validateParameter(valid_604657, JString, required = true,
                                 default = nil)
  if valid_604657 != nil:
    section.add "SourceDBClusterIdentifier", valid_604657
  var valid_604658 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604658 = validateParameter(valid_604658, JBool, required = false, default = nil)
  if valid_604658 != nil:
    section.add "UseLatestRestorableTime", valid_604658
  var valid_604659 = formData.getOrDefault("Port")
  valid_604659 = validateParameter(valid_604659, JInt, required = false, default = nil)
  if valid_604659 != nil:
    section.add "Port", valid_604659
  var valid_604660 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604660 = validateParameter(valid_604660, JArray, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "VpcSecurityGroupIds", valid_604660
  var valid_604661 = formData.getOrDefault("RestoreToTime")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "RestoreToTime", valid_604661
  var valid_604662 = formData.getOrDefault("Tags")
  valid_604662 = validateParameter(valid_604662, JArray, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "Tags", valid_604662
  var valid_604663 = formData.getOrDefault("DeletionProtection")
  valid_604663 = validateParameter(valid_604663, JBool, required = false, default = nil)
  if valid_604663 != nil:
    section.add "DeletionProtection", valid_604663
  var valid_604664 = formData.getOrDefault("DBSubnetGroupName")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "DBSubnetGroupName", valid_604664
  var valid_604665 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_604665 = validateParameter(valid_604665, JArray, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604665
  var valid_604666 = formData.getOrDefault("KmsKeyId")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "KmsKeyId", valid_604666
  var valid_604667 = formData.getOrDefault("DBClusterIdentifier")
  valid_604667 = validateParameter(valid_604667, JString, required = true,
                                 default = nil)
  if valid_604667 != nil:
    section.add "DBClusterIdentifier", valid_604667
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604668: Call_PostRestoreDBClusterToPointInTime_604645;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_604668.validator(path, query, header, formData, body)
  let scheme = call_604668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604668.url(scheme.get, call_604668.host, call_604668.base,
                         call_604668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604668, url, valid)

proc call*(call_604669: Call_PostRestoreDBClusterToPointInTime_604645;
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
  var query_604670 = newJObject()
  var formData_604671 = newJObject()
  add(formData_604671, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_604671, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_604671, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_604671.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604671, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_604671.add "Tags", Tags
  add(formData_604671, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604671, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604670, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_604671.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_604671, "KmsKeyId", newJString(KmsKeyId))
  add(formData_604671, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604670, "Version", newJString(Version))
  result = call_604669.call(nil, query_604670, nil, formData_604671, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_604645(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_604646, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_604647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_604619 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBClusterToPointInTime_604621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_604620(path: JsonNode;
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
  var valid_604622 = query.getOrDefault("RestoreToTime")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "RestoreToTime", valid_604622
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604623 = query.getOrDefault("DBClusterIdentifier")
  valid_604623 = validateParameter(valid_604623, JString, required = true,
                                 default = nil)
  if valid_604623 != nil:
    section.add "DBClusterIdentifier", valid_604623
  var valid_604624 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604624 = validateParameter(valid_604624, JArray, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "VpcSecurityGroupIds", valid_604624
  var valid_604625 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_604625 = validateParameter(valid_604625, JArray, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604625
  var valid_604626 = query.getOrDefault("Tags")
  valid_604626 = validateParameter(valid_604626, JArray, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "Tags", valid_604626
  var valid_604627 = query.getOrDefault("DeletionProtection")
  valid_604627 = validateParameter(valid_604627, JBool, required = false, default = nil)
  if valid_604627 != nil:
    section.add "DeletionProtection", valid_604627
  var valid_604628 = query.getOrDefault("UseLatestRestorableTime")
  valid_604628 = validateParameter(valid_604628, JBool, required = false, default = nil)
  if valid_604628 != nil:
    section.add "UseLatestRestorableTime", valid_604628
  var valid_604629 = query.getOrDefault("Action")
  valid_604629 = validateParameter(valid_604629, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_604629 != nil:
    section.add "Action", valid_604629
  var valid_604630 = query.getOrDefault("DBSubnetGroupName")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "DBSubnetGroupName", valid_604630
  var valid_604631 = query.getOrDefault("KmsKeyId")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "KmsKeyId", valid_604631
  var valid_604632 = query.getOrDefault("Port")
  valid_604632 = validateParameter(valid_604632, JInt, required = false, default = nil)
  if valid_604632 != nil:
    section.add "Port", valid_604632
  var valid_604633 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_604633 = validateParameter(valid_604633, JString, required = true,
                                 default = nil)
  if valid_604633 != nil:
    section.add "SourceDBClusterIdentifier", valid_604633
  var valid_604634 = query.getOrDefault("Version")
  valid_604634 = validateParameter(valid_604634, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604634 != nil:
    section.add "Version", valid_604634
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604635 = header.getOrDefault("X-Amz-Date")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Date", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-Security-Token")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-Security-Token", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Content-Sha256", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Algorithm")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Algorithm", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-Signature")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-Signature", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-SignedHeaders", valid_604640
  var valid_604641 = header.getOrDefault("X-Amz-Credential")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "X-Amz-Credential", valid_604641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604642: Call_GetRestoreDBClusterToPointInTime_604619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_604642.validator(path, query, header, formData, body)
  let scheme = call_604642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604642.url(scheme.get, call_604642.host, call_604642.base,
                         call_604642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604642, url, valid)

proc call*(call_604643: Call_GetRestoreDBClusterToPointInTime_604619;
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
  var query_604644 = newJObject()
  add(query_604644, "RestoreToTime", newJString(RestoreToTime))
  add(query_604644, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_604644.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_604644.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_604644.add "Tags", Tags
  add(query_604644, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604644, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_604644, "Action", newJString(Action))
  add(query_604644, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604644, "KmsKeyId", newJString(KmsKeyId))
  add(query_604644, "Port", newJInt(Port))
  add(query_604644, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_604644, "Version", newJString(Version))
  result = call_604643.call(nil, query_604644, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_604619(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_604620, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_604621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_604688 = ref object of OpenApiRestCall_602450
proc url_PostStartDBCluster_604690(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStartDBCluster_604689(path: JsonNode; query: JsonNode;
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
  var valid_604691 = query.getOrDefault("Action")
  valid_604691 = validateParameter(valid_604691, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_604691 != nil:
    section.add "Action", valid_604691
  var valid_604692 = query.getOrDefault("Version")
  valid_604692 = validateParameter(valid_604692, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604692 != nil:
    section.add "Version", valid_604692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604693 = header.getOrDefault("X-Amz-Date")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Date", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Security-Token")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Security-Token", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Content-Sha256", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-Algorithm")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Algorithm", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Signature")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Signature", valid_604697
  var valid_604698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604698 = validateParameter(valid_604698, JString, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "X-Amz-SignedHeaders", valid_604698
  var valid_604699 = header.getOrDefault("X-Amz-Credential")
  valid_604699 = validateParameter(valid_604699, JString, required = false,
                                 default = nil)
  if valid_604699 != nil:
    section.add "X-Amz-Credential", valid_604699
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604700 = formData.getOrDefault("DBClusterIdentifier")
  valid_604700 = validateParameter(valid_604700, JString, required = true,
                                 default = nil)
  if valid_604700 != nil:
    section.add "DBClusterIdentifier", valid_604700
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604701: Call_PostStartDBCluster_604688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604701.validator(path, query, header, formData, body)
  let scheme = call_604701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604701.url(scheme.get, call_604701.host, call_604701.base,
                         call_604701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604701, url, valid)

proc call*(call_604702: Call_PostStartDBCluster_604688;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_604703 = newJObject()
  var formData_604704 = newJObject()
  add(query_604703, "Action", newJString(Action))
  add(formData_604704, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604703, "Version", newJString(Version))
  result = call_604702.call(nil, query_604703, nil, formData_604704, nil)

var postStartDBCluster* = Call_PostStartDBCluster_604688(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_604689, base: "/",
    url: url_PostStartDBCluster_604690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_604672 = ref object of OpenApiRestCall_602450
proc url_GetStartDBCluster_604674(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStartDBCluster_604673(path: JsonNode; query: JsonNode;
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
  var valid_604675 = query.getOrDefault("DBClusterIdentifier")
  valid_604675 = validateParameter(valid_604675, JString, required = true,
                                 default = nil)
  if valid_604675 != nil:
    section.add "DBClusterIdentifier", valid_604675
  var valid_604676 = query.getOrDefault("Action")
  valid_604676 = validateParameter(valid_604676, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_604676 != nil:
    section.add "Action", valid_604676
  var valid_604677 = query.getOrDefault("Version")
  valid_604677 = validateParameter(valid_604677, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604677 != nil:
    section.add "Version", valid_604677
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604678 = header.getOrDefault("X-Amz-Date")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Date", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Security-Token")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Security-Token", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Content-Sha256", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-Algorithm")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-Algorithm", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-Signature")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Signature", valid_604682
  var valid_604683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604683 = validateParameter(valid_604683, JString, required = false,
                                 default = nil)
  if valid_604683 != nil:
    section.add "X-Amz-SignedHeaders", valid_604683
  var valid_604684 = header.getOrDefault("X-Amz-Credential")
  valid_604684 = validateParameter(valid_604684, JString, required = false,
                                 default = nil)
  if valid_604684 != nil:
    section.add "X-Amz-Credential", valid_604684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604685: Call_GetStartDBCluster_604672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604685.validator(path, query, header, formData, body)
  let scheme = call_604685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604685.url(scheme.get, call_604685.host, call_604685.base,
                         call_604685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604685, url, valid)

proc call*(call_604686: Call_GetStartDBCluster_604672; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604687 = newJObject()
  add(query_604687, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604687, "Action", newJString(Action))
  add(query_604687, "Version", newJString(Version))
  result = call_604686.call(nil, query_604687, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_604672(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_604673,
    base: "/", url: url_GetStartDBCluster_604674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_604721 = ref object of OpenApiRestCall_602450
proc url_PostStopDBCluster_604723(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStopDBCluster_604722(path: JsonNode; query: JsonNode;
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
  var valid_604724 = query.getOrDefault("Action")
  valid_604724 = validateParameter(valid_604724, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_604724 != nil:
    section.add "Action", valid_604724
  var valid_604725 = query.getOrDefault("Version")
  valid_604725 = validateParameter(valid_604725, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604725 != nil:
    section.add "Version", valid_604725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604726 = header.getOrDefault("X-Amz-Date")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-Date", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Security-Token")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Security-Token", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Content-Sha256", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-Algorithm")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Algorithm", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-Signature")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Signature", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-SignedHeaders", valid_604731
  var valid_604732 = header.getOrDefault("X-Amz-Credential")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "X-Amz-Credential", valid_604732
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604733 = formData.getOrDefault("DBClusterIdentifier")
  valid_604733 = validateParameter(valid_604733, JString, required = true,
                                 default = nil)
  if valid_604733 != nil:
    section.add "DBClusterIdentifier", valid_604733
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604734: Call_PostStopDBCluster_604721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604734.validator(path, query, header, formData, body)
  let scheme = call_604734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604734.url(scheme.get, call_604734.host, call_604734.base,
                         call_604734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604734, url, valid)

proc call*(call_604735: Call_PostStopDBCluster_604721; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_604736 = newJObject()
  var formData_604737 = newJObject()
  add(query_604736, "Action", newJString(Action))
  add(formData_604737, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604736, "Version", newJString(Version))
  result = call_604735.call(nil, query_604736, nil, formData_604737, nil)

var postStopDBCluster* = Call_PostStopDBCluster_604721(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_604722,
    base: "/", url: url_PostStopDBCluster_604723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_604705 = ref object of OpenApiRestCall_602450
proc url_GetStopDBCluster_604707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStopDBCluster_604706(path: JsonNode; query: JsonNode;
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
  var valid_604708 = query.getOrDefault("DBClusterIdentifier")
  valid_604708 = validateParameter(valid_604708, JString, required = true,
                                 default = nil)
  if valid_604708 != nil:
    section.add "DBClusterIdentifier", valid_604708
  var valid_604709 = query.getOrDefault("Action")
  valid_604709 = validateParameter(valid_604709, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_604709 != nil:
    section.add "Action", valid_604709
  var valid_604710 = query.getOrDefault("Version")
  valid_604710 = validateParameter(valid_604710, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604710 != nil:
    section.add "Version", valid_604710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604711 = header.getOrDefault("X-Amz-Date")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-Date", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Security-Token")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Security-Token", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Content-Sha256", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Algorithm")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Algorithm", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Signature")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Signature", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-SignedHeaders", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-Credential")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-Credential", valid_604717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604718: Call_GetStopDBCluster_604705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604718.validator(path, query, header, formData, body)
  let scheme = call_604718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604718.url(scheme.get, call_604718.host, call_604718.base,
                         call_604718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604718, url, valid)

proc call*(call_604719: Call_GetStopDBCluster_604705; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604720 = newJObject()
  add(query_604720, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604720, "Action", newJString(Action))
  add(query_604720, "Version", newJString(Version))
  result = call_604719.call(nil, query_604720, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_604705(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_604706,
    base: "/", url: url_GetStopDBCluster_604707,
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
