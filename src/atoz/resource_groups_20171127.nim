
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateGroup_610996 = ref object of OpenApiRestCall_610658
proc url_CreateGroup_610998(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_CreateGroup_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_CreateGroup_610996; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   body: JObject (required)
  var body_611212 = newJObject()
  if body != nil:
    body_611212 = body
  result = call_611211.call(nil, nil, nil, nil, body_611212)

var createGroup* = Call_CreateGroup_610996(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups",
                                        validator: validate_CreateGroup_610997,
                                        base: "/", url: url_CreateGroup_610998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_611280 = ref object of OpenApiRestCall_610658
proc url_UpdateGroup_611282(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_611281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611283 = path.getOrDefault("GroupName")
  valid_611283 = validateParameter(valid_611283, JString, required = true,
                                 default = nil)
  if valid_611283 != nil:
    section.add "GroupName", valid_611283
  result.add "path", section
  section = newJObject()
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
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_UpdateGroup_611280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_UpdateGroup_611280; GroupName: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to update its description.
  ##   body: JObject (required)
  var path_611294 = newJObject()
  var body_611295 = newJObject()
  add(path_611294, "GroupName", newJString(GroupName))
  if body != nil:
    body_611295 = body
  result = call_611293.call(path_611294, nil, nil, nil, body_611295)

var updateGroup* = Call_UpdateGroup_611280(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_UpdateGroup_611281,
                                        base: "/", url: url_UpdateGroup_611282,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_611251 = ref object of OpenApiRestCall_610658
proc url_GetGroup_611253(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroup_611252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611268 = path.getOrDefault("GroupName")
  valid_611268 = validateParameter(valid_611268, JString, required = true,
                                 default = nil)
  if valid_611268 != nil:
    section.add "GroupName", valid_611268
  result.add "path", section
  section = newJObject()
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
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_GetGroup_611251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified resource group.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_GetGroup_611251; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_611278 = newJObject()
  add(path_611278, "GroupName", newJString(GroupName))
  result = call_611277.call(path_611278, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_611251(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/groups/{GroupName}",
                                  validator: validate_GetGroup_611252, base: "/",
                                  url: url_GetGroup_611253,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_611296 = ref object of OpenApiRestCall_610658
proc url_DeleteGroup_611298(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_611297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611299 = path.getOrDefault("GroupName")
  valid_611299 = validateParameter(valid_611299, JString, required = true,
                                 default = nil)
  if valid_611299 != nil:
    section.add "GroupName", valid_611299
  result.add "path", section
  section = newJObject()
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
  var valid_611300 = header.getOrDefault("X-Amz-Signature")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Signature", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Content-Sha256", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Date")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Date", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Credential")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Credential", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Security-Token")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Security-Token", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Algorithm")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Algorithm", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-SignedHeaders", valid_611306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_DeleteGroup_611296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_DeleteGroup_611296; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   GroupName: string (required)
  ##            : The name of the resource group to delete.
  var path_611309 = newJObject()
  add(path_611309, "GroupName", newJString(GroupName))
  result = call_611308.call(path_611309, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_611296(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_DeleteGroup_611297,
                                        base: "/", url: url_DeleteGroup_611298,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_611324 = ref object of OpenApiRestCall_610658
proc url_UpdateGroupQuery_611326(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroupQuery_611325(path: JsonNode; query: JsonNode;
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
  var valid_611327 = path.getOrDefault("GroupName")
  valid_611327 = validateParameter(valid_611327, JString, required = true,
                                 default = nil)
  if valid_611327 != nil:
    section.add "GroupName", valid_611327
  result.add "path", section
  section = newJObject()
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
  var valid_611328 = header.getOrDefault("X-Amz-Signature")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Signature", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Content-Sha256", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Date")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Date", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Credential")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Credential", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Security-Token")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Security-Token", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Algorithm")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Algorithm", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-SignedHeaders", valid_611334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611336: Call_UpdateGroupQuery_611324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource query of a group.
  ## 
  let valid = call_611336.validator(path, query, header, formData, body)
  let scheme = call_611336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611336.url(scheme.get, call_611336.host, call_611336.base,
                         call_611336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611336, url, valid)

proc call*(call_611337: Call_UpdateGroupQuery_611324; GroupName: string;
          body: JsonNode): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to edit the query.
  ##   body: JObject (required)
  var path_611338 = newJObject()
  var body_611339 = newJObject()
  add(path_611338, "GroupName", newJString(GroupName))
  if body != nil:
    body_611339 = body
  result = call_611337.call(path_611338, nil, nil, nil, body_611339)

var updateGroupQuery* = Call_UpdateGroupQuery_611324(name: "updateGroupQuery",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_UpdateGroupQuery_611325,
    base: "/", url: url_UpdateGroupQuery_611326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_611310 = ref object of OpenApiRestCall_610658
proc url_GetGroupQuery_611312(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupQuery_611311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611313 = path.getOrDefault("GroupName")
  valid_611313 = validateParameter(valid_611313, JString, required = true,
                                 default = nil)
  if valid_611313 != nil:
    section.add "GroupName", valid_611313
  result.add "path", section
  section = newJObject()
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
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611321: Call_GetGroupQuery_611310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the resource query associated with the specified resource group.
  ## 
  let valid = call_611321.validator(path, query, header, formData, body)
  let scheme = call_611321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611321.url(scheme.get, call_611321.host, call_611321.base,
                         call_611321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611321, url, valid)

proc call*(call_611322: Call_GetGroupQuery_611310; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_611323 = newJObject()
  add(path_611323, "GroupName", newJString(GroupName))
  result = call_611322.call(path_611323, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_611310(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_611311,
    base: "/", url: url_GetGroupQuery_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_611354 = ref object of OpenApiRestCall_610658
proc url_Tag_611356(protocol: Scheme; host: string; base: string; route: string;
                   path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Tag_611355(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611357 = path.getOrDefault("Arn")
  valid_611357 = validateParameter(valid_611357, JString, required = true,
                                 default = nil)
  if valid_611357 != nil:
    section.add "Arn", valid_611357
  result.add "path", section
  section = newJObject()
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
  var valid_611358 = header.getOrDefault("X-Amz-Signature")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Signature", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Content-Sha256", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Date")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Date", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Credential")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Credential", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Security-Token")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Security-Token", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Algorithm")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Algorithm", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-SignedHeaders", valid_611364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611366: Call_Tag_611354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_611366.validator(path, query, header, formData, body)
  let scheme = call_611366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611366.url(scheme.get, call_611366.host, call_611366.base,
                         call_611366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611366, url, valid)

proc call*(call_611367: Call_Tag_611354; body: JsonNode; Arn: string): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  ##   Arn: string (required)
  ##      : The ARN of the resource to which to add tags.
  var path_611368 = newJObject()
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  add(path_611368, "Arn", newJString(Arn))
  result = call_611367.call(path_611368, nil, nil, nil, body_611369)

var tag* = Call_Tag_611354(name: "tag", meth: HttpMethod.HttpPut,
                        host: "resource-groups.amazonaws.com",
                        route: "/resources/{Arn}/tags", validator: validate_Tag_611355,
                        base: "/", url: url_Tag_611356,
                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_611340 = ref object of OpenApiRestCall_610658
proc url_GetTags_611342(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_611341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611343 = path.getOrDefault("Arn")
  valid_611343 = validateParameter(valid_611343, JString, required = true,
                                 default = nil)
  if valid_611343 != nil:
    section.add "Arn", valid_611343
  result.add "path", section
  section = newJObject()
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
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611351: Call_GetTags_611340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  let valid = call_611351.validator(path, query, header, formData, body)
  let scheme = call_611351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611351.url(scheme.get, call_611351.host, call_611351.base,
                         call_611351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611351, url, valid)

proc call*(call_611352: Call_GetTags_611340; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   Arn: string (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  var path_611353 = newJObject()
  add(path_611353, "Arn", newJString(Arn))
  result = call_611352.call(path_611353, nil, nil, nil, nil)

var getTags* = Call_GetTags_611340(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "resource-groups.amazonaws.com",
                                route: "/resources/{Arn}/tags",
                                validator: validate_GetTags_611341, base: "/",
                                url: url_GetTags_611342,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_611370 = ref object of OpenApiRestCall_610658
proc url_Untag_611372(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Untag_611371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611373 = path.getOrDefault("Arn")
  valid_611373 = validateParameter(valid_611373, JString, required = true,
                                 default = nil)
  if valid_611373 != nil:
    section.add "Arn", valid_611373
  result.add "path", section
  section = newJObject()
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
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_Untag_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a specified resource.
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_Untag_611370; body: JsonNode; Arn: string): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   body: JObject (required)
  ##   Arn: string (required)
  ##      : The ARN of the resource from which to remove tags.
  var path_611384 = newJObject()
  var body_611385 = newJObject()
  if body != nil:
    body_611385 = body
  add(path_611384, "Arn", newJString(Arn))
  result = call_611383.call(path_611384, nil, nil, nil, body_611385)

var untag* = Call_Untag_611370(name: "untag", meth: HttpMethod.HttpPatch,
                            host: "resource-groups.amazonaws.com",
                            route: "/resources/{Arn}/tags",
                            validator: validate_Untag_611371, base: "/",
                            url: url_Untag_611372,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_611386 = ref object of OpenApiRestCall_610658
proc url_ListGroupResources_611388(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/resource-identifiers-list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupResources_611387(path: JsonNode; query: JsonNode;
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
  var valid_611389 = path.getOrDefault("GroupName")
  valid_611389 = validateParameter(valid_611389, JString, required = true,
                                 default = nil)
  if valid_611389 != nil:
    section.add "GroupName", valid_611389
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  section = newJObject()
  var valid_611390 = query.getOrDefault("nextToken")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "nextToken", valid_611390
  var valid_611391 = query.getOrDefault("MaxResults")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "MaxResults", valid_611391
  var valid_611392 = query.getOrDefault("NextToken")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "NextToken", valid_611392
  var valid_611393 = query.getOrDefault("maxResults")
  valid_611393 = validateParameter(valid_611393, JInt, required = false, default = nil)
  if valid_611393 != nil:
    section.add "maxResults", valid_611393
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
  var valid_611394 = header.getOrDefault("X-Amz-Signature")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Signature", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Content-Sha256", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Date")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Date", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Credential")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Credential", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Security-Token")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Security-Token", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Algorithm")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Algorithm", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-SignedHeaders", valid_611400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611402: Call_ListGroupResources_611386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  let valid = call_611402.validator(path, query, header, formData, body)
  let scheme = call_611402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611402.url(scheme.get, call_611402.host, call_611402.base,
                         call_611402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611402, url, valid)

proc call*(call_611403: Call_ListGroupResources_611386; GroupName: string;
          body: JsonNode; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listGroupResources
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: int
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  var path_611404 = newJObject()
  var query_611405 = newJObject()
  var body_611406 = newJObject()
  add(path_611404, "GroupName", newJString(GroupName))
  add(query_611405, "nextToken", newJString(nextToken))
  add(query_611405, "MaxResults", newJString(MaxResults))
  add(query_611405, "NextToken", newJString(NextToken))
  if body != nil:
    body_611406 = body
  add(query_611405, "maxResults", newJInt(maxResults))
  result = call_611403.call(path_611404, query_611405, nil, nil, body_611406)

var listGroupResources* = Call_ListGroupResources_611386(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_611387, base: "/",
    url: url_ListGroupResources_611388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_611407 = ref object of OpenApiRestCall_610658
proc url_ListGroups_611409(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_611408(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing resource groups in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  section = newJObject()
  var valid_611410 = query.getOrDefault("nextToken")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "nextToken", valid_611410
  var valid_611411 = query.getOrDefault("MaxResults")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "MaxResults", valid_611411
  var valid_611412 = query.getOrDefault("NextToken")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "NextToken", valid_611412
  var valid_611413 = query.getOrDefault("maxResults")
  valid_611413 = validateParameter(valid_611413, JInt, required = false, default = nil)
  if valid_611413 != nil:
    section.add "maxResults", valid_611413
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
  var valid_611414 = header.getOrDefault("X-Amz-Signature")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Signature", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Content-Sha256", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Date")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Date", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Credential")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Credential", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Security-Token")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Security-Token", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Algorithm")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Algorithm", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-SignedHeaders", valid_611420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611422: Call_ListGroups_611407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing resource groups in your account.
  ## 
  let valid = call_611422.validator(path, query, header, formData, body)
  let scheme = call_611422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611422.url(scheme.get, call_611422.host, call_611422.base,
                         call_611422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611422, url, valid)

proc call*(call_611423: Call_ListGroups_611407; body: JsonNode;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGroups
  ## Returns a list of existing resource groups in your account.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: int
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  var query_611424 = newJObject()
  var body_611425 = newJObject()
  add(query_611424, "nextToken", newJString(nextToken))
  add(query_611424, "MaxResults", newJString(MaxResults))
  add(query_611424, "NextToken", newJString(NextToken))
  if body != nil:
    body_611425 = body
  add(query_611424, "maxResults", newJInt(maxResults))
  result = call_611423.call(nil, query_611424, nil, nil, body_611425)

var listGroups* = Call_ListGroups_611407(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/groups-list",
                                      validator: validate_ListGroups_611408,
                                      base: "/", url: url_ListGroups_611409,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_611426 = ref object of OpenApiRestCall_610658
proc url_SearchResources_611428(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchResources_611427(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611429 = query.getOrDefault("MaxResults")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "MaxResults", valid_611429
  var valid_611430 = query.getOrDefault("NextToken")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "NextToken", valid_611430
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
  var valid_611431 = header.getOrDefault("X-Amz-Signature")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Signature", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Content-Sha256", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Date")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Date", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Credential")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Credential", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Security-Token")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Security-Token", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Algorithm")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Algorithm", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-SignedHeaders", valid_611437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611439: Call_SearchResources_611426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  let valid = call_611439.validator(path, query, header, formData, body)
  let scheme = call_611439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611439.url(scheme.get, call_611439.host, call_611439.base,
                         call_611439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611439, url, valid)

proc call*(call_611440: Call_SearchResources_611426; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611441 = newJObject()
  var body_611442 = newJObject()
  add(query_611441, "MaxResults", newJString(MaxResults))
  add(query_611441, "NextToken", newJString(NextToken))
  if body != nil:
    body_611442 = body
  result = call_611440.call(nil, query_611441, nil, nil, body_611442)

var searchResources* = Call_SearchResources_611426(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_611427,
    base: "/", url: url_SearchResources_611428, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
