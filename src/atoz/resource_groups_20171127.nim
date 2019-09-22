
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Groups
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Resource Groups</fullname> <p>AWS Resource Groups lets you organize AWS resources such as Amazon EC2 instances, Amazon Relational Database Service databases, and Amazon S3 buckets into groups using criteria that you define as tags. A resource group is a collection of resources that match the resource types specified in a query, and share one or more tags or portions of tags. You can create a group of resources based on their roles in your cloud infrastructure, lifecycle stages, regions, application layers, or virtually any criteria. Resource groups enable you to automate management tasks, such as those in AWS Systems Manager Automation documents, on tag-related resources in AWS Systems Manager. Groups of tagged resources also let you quickly view a custom console in AWS Systems Manager that shows AWS Config compliance and other monitoring data about member resources.</p> <p>To create a resource group, build a resource query, and specify tags that identify the criteria that members of the group have in common. Tags are key-value pairs.</p> <p>For more information about Resource Groups, see the <a href="https://docs.aws.amazon.com/ARG/latest/userguide/welcome.html">AWS Resource Groups User Guide</a>.</p> <p>AWS Resource Groups uses a REST-compliant API that you can use to perform the following types of operations.</p> <ul> <li> <p>Create, Read, Update, and Delete (CRUD) operations on resource groups and resource query entities</p> </li> <li> <p>Applying, editing, and removing tags from resource groups</p> </li> <li> <p>Resolving resource group member ARNs so they can be returned as search results</p> </li> <li> <p>Getting data about resources that are members of a group</p> </li> <li> <p>Searching AWS resources based on a resource query</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/resource-groups/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "resource-groups.ap-northeast-1.amazonaws.com", "ap-southeast-1": "resource-groups.ap-southeast-1.amazonaws.com", "us-west-2": "resource-groups.us-west-2.amazonaws.com", "eu-west-2": "resource-groups.eu-west-2.amazonaws.com", "ap-northeast-3": "resource-groups.ap-northeast-3.amazonaws.com", "eu-central-1": "resource-groups.eu-central-1.amazonaws.com", "us-east-2": "resource-groups.us-east-2.amazonaws.com", "us-east-1": "resource-groups.us-east-1.amazonaws.com", "cn-northwest-1": "resource-groups.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "resource-groups.ap-south-1.amazonaws.com", "eu-north-1": "resource-groups.eu-north-1.amazonaws.com", "ap-northeast-2": "resource-groups.ap-northeast-2.amazonaws.com", "us-west-1": "resource-groups.us-west-1.amazonaws.com", "us-gov-east-1": "resource-groups.us-gov-east-1.amazonaws.com", "eu-west-3": "resource-groups.eu-west-3.amazonaws.com", "cn-north-1": "resource-groups.cn-north-1.amazonaws.com.cn", "sa-east-1": "resource-groups.sa-east-1.amazonaws.com", "eu-west-1": "resource-groups.eu-west-1.amazonaws.com", "us-gov-west-1": "resource-groups.us-gov-west-1.amazonaws.com", "ap-southeast-2": "resource-groups.ap-southeast-2.amazonaws.com", "ca-central-1": "resource-groups.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "resource-groups.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "resource-groups.ap-southeast-1.amazonaws.com",
      "us-west-2": "resource-groups.us-west-2.amazonaws.com",
      "eu-west-2": "resource-groups.eu-west-2.amazonaws.com",
      "ap-northeast-3": "resource-groups.ap-northeast-3.amazonaws.com",
      "eu-central-1": "resource-groups.eu-central-1.amazonaws.com",
      "us-east-2": "resource-groups.us-east-2.amazonaws.com",
      "us-east-1": "resource-groups.us-east-1.amazonaws.com",
      "cn-northwest-1": "resource-groups.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "resource-groups.ap-south-1.amazonaws.com",
      "eu-north-1": "resource-groups.eu-north-1.amazonaws.com",
      "ap-northeast-2": "resource-groups.ap-northeast-2.amazonaws.com",
      "us-west-1": "resource-groups.us-west-1.amazonaws.com",
      "us-gov-east-1": "resource-groups.us-gov-east-1.amazonaws.com",
      "eu-west-3": "resource-groups.eu-west-3.amazonaws.com",
      "cn-north-1": "resource-groups.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "resource-groups.sa-east-1.amazonaws.com",
      "eu-west-1": "resource-groups.eu-west-1.amazonaws.com",
      "us-gov-west-1": "resource-groups.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "resource-groups.ap-southeast-2.amazonaws.com",
      "ca-central-1": "resource-groups.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "resource-groups"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateGroup_602770 = ref object of OpenApiRestCall_602433
proc url_CreateGroup_602772(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_602771(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Signature")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Signature", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_CreateGroup_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602985: Call_CreateGroup_602770; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   body: JObject (required)
  var body_602986 = newJObject()
  if body != nil:
    body_602986 = body
  result = call_602985.call(nil, nil, nil, nil, body_602986)

var createGroup* = Call_CreateGroup_602770(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups",
                                        validator: validate_CreateGroup_602771,
                                        base: "/", url: url_CreateGroup_602772,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_603054 = ref object of OpenApiRestCall_602433
proc url_UpdateGroup_603056(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateGroup_603055(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group for which you want to update its description.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603057 = path.getOrDefault("GroupName")
  valid_603057 = validateParameter(valid_603057, JString, required = true,
                                 default = nil)
  if valid_603057 != nil:
    section.add "GroupName", valid_603057
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603058 = header.getOrDefault("X-Amz-Date")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Date", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Security-Token")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Security-Token", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_UpdateGroup_603054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_UpdateGroup_603054; GroupName: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to update its description.
  ##   body: JObject (required)
  var path_603068 = newJObject()
  var body_603069 = newJObject()
  add(path_603068, "GroupName", newJString(GroupName))
  if body != nil:
    body_603069 = body
  result = call_603067.call(path_603068, nil, nil, nil, body_603069)

var updateGroup* = Call_UpdateGroup_603054(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_UpdateGroup_603055,
                                        base: "/", url: url_UpdateGroup_603056,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_603025 = ref object of OpenApiRestCall_602433
proc url_GetGroup_603027(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetGroup_603026(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603042 = path.getOrDefault("GroupName")
  valid_603042 = validateParameter(valid_603042, JString, required = true,
                                 default = nil)
  if valid_603042 != nil:
    section.add "GroupName", valid_603042
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603043 = header.getOrDefault("X-Amz-Date")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Date", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Security-Token")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Security-Token", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603050: Call_GetGroup_603025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified resource group.
  ## 
  let valid = call_603050.validator(path, query, header, formData, body)
  let scheme = call_603050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603050.url(scheme.get, call_603050.host, call_603050.base,
                         call_603050.route, valid.getOrDefault("path"))
  result = hook(call_603050, url, valid)

proc call*(call_603051: Call_GetGroup_603025; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_603052 = newJObject()
  add(path_603052, "GroupName", newJString(GroupName))
  result = call_603051.call(path_603052, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_603025(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/groups/{GroupName}",
                                  validator: validate_GetGroup_603026, base: "/",
                                  url: url_GetGroup_603027,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_603070 = ref object of OpenApiRestCall_602433
proc url_DeleteGroup_603072(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteGroup_603071(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603073 = path.getOrDefault("GroupName")
  valid_603073 = validateParameter(valid_603073, JString, required = true,
                                 default = nil)
  if valid_603073 != nil:
    section.add "GroupName", valid_603073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603074 = header.getOrDefault("X-Amz-Date")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Date", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Security-Token")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Security-Token", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Content-Sha256", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Algorithm")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Algorithm", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Signature")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Signature", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-SignedHeaders", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Credential")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Credential", valid_603080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_DeleteGroup_603070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DeleteGroup_603070; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   GroupName: string (required)
  ##            : The name of the resource group to delete.
  var path_603083 = newJObject()
  add(path_603083, "GroupName", newJString(GroupName))
  result = call_603082.call(path_603083, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_603070(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_DeleteGroup_603071,
                                        base: "/", url: url_DeleteGroup_603072,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_603098 = ref object of OpenApiRestCall_602433
proc url_UpdateGroupQuery_603100(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateGroupQuery_603099(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the resource query of a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group for which you want to edit the query.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603101 = path.getOrDefault("GroupName")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = nil)
  if valid_603101 != nil:
    section.add "GroupName", valid_603101
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Content-Sha256", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Signature")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Signature", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_UpdateGroupQuery_603098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource query of a group.
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_UpdateGroupQuery_603098; GroupName: string;
          body: JsonNode): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to edit the query.
  ##   body: JObject (required)
  var path_603112 = newJObject()
  var body_603113 = newJObject()
  add(path_603112, "GroupName", newJString(GroupName))
  if body != nil:
    body_603113 = body
  result = call_603111.call(path_603112, nil, nil, nil, body_603113)

var updateGroupQuery* = Call_UpdateGroupQuery_603098(name: "updateGroupQuery",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_UpdateGroupQuery_603099,
    base: "/", url: url_UpdateGroupQuery_603100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_603084 = ref object of OpenApiRestCall_602433
proc url_GetGroupQuery_603086(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetGroupQuery_603085(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the resource query associated with the specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603087 = path.getOrDefault("GroupName")
  valid_603087 = validateParameter(valid_603087, JString, required = true,
                                 default = nil)
  if valid_603087 != nil:
    section.add "GroupName", valid_603087
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603088 = header.getOrDefault("X-Amz-Date")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Date", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Security-Token")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Security-Token", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603095: Call_GetGroupQuery_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the resource query associated with the specified resource group.
  ## 
  let valid = call_603095.validator(path, query, header, formData, body)
  let scheme = call_603095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603095.url(scheme.get, call_603095.host, call_603095.base,
                         call_603095.route, valid.getOrDefault("path"))
  result = hook(call_603095, url, valid)

proc call*(call_603096: Call_GetGroupQuery_603084; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_603097 = newJObject()
  add(path_603097, "GroupName", newJString(GroupName))
  result = call_603096.call(path_603097, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_603084(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_603085,
    base: "/", url: url_GetGroupQuery_603086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_603128 = ref object of OpenApiRestCall_602433
proc url_Tag_603130(protocol: Scheme; host: string; base: string; route: string;
                   path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_Tag_603129(path: JsonNode; query: JsonNode; header: JsonNode;
                        formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource to which to add tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_603131 = path.getOrDefault("Arn")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "Arn", valid_603131
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Algorithm")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Algorithm", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-SignedHeaders", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Credential")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Credential", valid_603138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603140: Call_Tag_603128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_603140.validator(path, query, header, formData, body)
  let scheme = call_603140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603140.url(scheme.get, call_603140.host, call_603140.base,
                         call_603140.route, valid.getOrDefault("path"))
  result = hook(call_603140, url, valid)

proc call*(call_603141: Call_Tag_603128; Arn: string; body: JsonNode): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   Arn: string (required)
  ##      : The ARN of the resource to which to add tags.
  ##   body: JObject (required)
  var path_603142 = newJObject()
  var body_603143 = newJObject()
  add(path_603142, "Arn", newJString(Arn))
  if body != nil:
    body_603143 = body
  result = call_603141.call(path_603142, nil, nil, nil, body_603143)

var tag* = Call_Tag_603128(name: "tag", meth: HttpMethod.HttpPut,
                        host: "resource-groups.amazonaws.com",
                        route: "/resources/{Arn}/tags", validator: validate_Tag_603129,
                        base: "/", url: url_Tag_603130,
                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_603114 = ref object of OpenApiRestCall_602433
proc url_GetTags_603116(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetTags_603115(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_603117 = path.getOrDefault("Arn")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "Arn", valid_603117
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603125: Call_GetTags_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  let valid = call_603125.validator(path, query, header, formData, body)
  let scheme = call_603125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603125.url(scheme.get, call_603125.host, call_603125.base,
                         call_603125.route, valid.getOrDefault("path"))
  result = hook(call_603125, url, valid)

proc call*(call_603126: Call_GetTags_603114; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   Arn: string (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  var path_603127 = newJObject()
  add(path_603127, "Arn", newJString(Arn))
  result = call_603126.call(path_603127, nil, nil, nil, nil)

var getTags* = Call_GetTags_603114(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "resource-groups.amazonaws.com",
                                route: "/resources/{Arn}/tags",
                                validator: validate_GetTags_603115, base: "/",
                                url: url_GetTags_603116,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_603144 = ref object of OpenApiRestCall_602433
proc url_Untag_603146(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_Untag_603145(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource from which to remove tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_603147 = path.getOrDefault("Arn")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "Arn", valid_603147
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_Untag_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a specified resource.
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_Untag_603144; Arn: string; body: JsonNode): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   Arn: string (required)
  ##      : The ARN of the resource from which to remove tags.
  ##   body: JObject (required)
  var path_603158 = newJObject()
  var body_603159 = newJObject()
  add(path_603158, "Arn", newJString(Arn))
  if body != nil:
    body_603159 = body
  result = call_603157.call(path_603158, nil, nil, nil, body_603159)

var untag* = Call_Untag_603144(name: "untag", meth: HttpMethod.HttpPatch,
                            host: "resource-groups.amazonaws.com",
                            route: "/resources/{Arn}/tags",
                            validator: validate_Untag_603145, base: "/",
                            url: url_Untag_603146,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_603160 = ref object of OpenApiRestCall_602433
proc url_ListGroupResources_603162(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/resource-identifiers-list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListGroupResources_603161(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_603163 = path.getOrDefault("GroupName")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "GroupName", valid_603163
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603164 = query.getOrDefault("NextToken")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "NextToken", valid_603164
  var valid_603165 = query.getOrDefault("maxResults")
  valid_603165 = validateParameter(valid_603165, JInt, required = false, default = nil)
  if valid_603165 != nil:
    section.add "maxResults", valid_603165
  var valid_603166 = query.getOrDefault("nextToken")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "nextToken", valid_603166
  var valid_603167 = query.getOrDefault("MaxResults")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "MaxResults", valid_603167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603168 = header.getOrDefault("X-Amz-Date")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Date", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Security-Token")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Security-Token", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Content-Sha256", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Algorithm")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Algorithm", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Signature")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Signature", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-SignedHeaders", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Credential")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Credential", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_ListGroupResources_603160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"))
  result = hook(call_603176, url, valid)

proc call*(call_603177: Call_ListGroupResources_603160; GroupName: string;
          body: JsonNode; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupResources
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603178 = newJObject()
  var query_603179 = newJObject()
  var body_603180 = newJObject()
  add(path_603178, "GroupName", newJString(GroupName))
  add(query_603179, "NextToken", newJString(NextToken))
  add(query_603179, "maxResults", newJInt(maxResults))
  add(query_603179, "nextToken", newJString(nextToken))
  if body != nil:
    body_603180 = body
  add(query_603179, "MaxResults", newJString(MaxResults))
  result = call_603177.call(path_603178, query_603179, nil, nil, body_603180)

var listGroupResources* = Call_ListGroupResources_603160(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_603161, base: "/",
    url: url_ListGroupResources_603162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_603181 = ref object of OpenApiRestCall_602433
proc url_ListGroups_603183(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGroups_603182(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing resource groups in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603184 = query.getOrDefault("NextToken")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "NextToken", valid_603184
  var valid_603185 = query.getOrDefault("maxResults")
  valid_603185 = validateParameter(valid_603185, JInt, required = false, default = nil)
  if valid_603185 != nil:
    section.add "maxResults", valid_603185
  var valid_603186 = query.getOrDefault("nextToken")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "nextToken", valid_603186
  var valid_603187 = query.getOrDefault("MaxResults")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "MaxResults", valid_603187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603188 = header.getOrDefault("X-Amz-Date")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Date", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Algorithm")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Algorithm", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Signature")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Signature", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-SignedHeaders", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Credential")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Credential", valid_603194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_ListGroups_603181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing resource groups in your account.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_ListGroups_603181; body: JsonNode;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Returns a list of existing resource groups in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603198 = newJObject()
  var body_603199 = newJObject()
  add(query_603198, "NextToken", newJString(NextToken))
  add(query_603198, "maxResults", newJInt(maxResults))
  add(query_603198, "nextToken", newJString(nextToken))
  if body != nil:
    body_603199 = body
  add(query_603198, "MaxResults", newJString(MaxResults))
  result = call_603197.call(nil, query_603198, nil, nil, body_603199)

var listGroups* = Call_ListGroups_603181(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/groups-list",
                                      validator: validate_ListGroups_603182,
                                      base: "/", url: url_ListGroups_603183,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_603200 = ref object of OpenApiRestCall_602433
proc url_SearchResources_603202(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchResources_603201(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603203 = query.getOrDefault("NextToken")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "NextToken", valid_603203
  var valid_603204 = query.getOrDefault("MaxResults")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "MaxResults", valid_603204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Content-Sha256", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_SearchResources_603200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_SearchResources_603200; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603215 = newJObject()
  var body_603216 = newJObject()
  add(query_603215, "NextToken", newJString(NextToken))
  if body != nil:
    body_603216 = body
  add(query_603215, "MaxResults", newJString(MaxResults))
  result = call_603214.call(nil, query_603215, nil, nil, body_603216)

var searchResources* = Call_SearchResources_603200(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_603201,
    base: "/", url: url_SearchResources_603202, schemes: {Scheme.Https, Scheme.Http})
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
