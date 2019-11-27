
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateGroup_599705 = ref object of OpenApiRestCall_599368
proc url_CreateGroup_599707(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_CreateGroup_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_CreateGroup_599705; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var createGroup* = Call_CreateGroup_599705(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups",
                                        validator: validate_CreateGroup_599706,
                                        base: "/", url: url_CreateGroup_599707,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_599989 = ref object of OpenApiRestCall_599368
proc url_UpdateGroup_599991(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_599990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599992 = path.getOrDefault("GroupName")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = nil)
  if valid_599992 != nil:
    section.add "GroupName", valid_599992
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
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_UpdateGroup_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_UpdateGroup_599989; GroupName: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to update its description.
  ##   body: JObject (required)
  var path_600003 = newJObject()
  var body_600004 = newJObject()
  add(path_600003, "GroupName", newJString(GroupName))
  if body != nil:
    body_600004 = body
  result = call_600002.call(path_600003, nil, nil, nil, body_600004)

var updateGroup* = Call_UpdateGroup_599989(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_UpdateGroup_599990,
                                        base: "/", url: url_UpdateGroup_599991,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_599960 = ref object of OpenApiRestCall_599368
proc url_GetGroup_599962(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroup_599961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599977 = path.getOrDefault("GroupName")
  valid_599977 = validateParameter(valid_599977, JString, required = true,
                                 default = nil)
  if valid_599977 != nil:
    section.add "GroupName", valid_599977
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
  var valid_599978 = header.getOrDefault("X-Amz-Date")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Date", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Security-Token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Security-Token", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_GetGroup_599960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified resource group.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_GetGroup_599960; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_599987 = newJObject()
  add(path_599987, "GroupName", newJString(GroupName))
  result = call_599986.call(path_599987, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_599960(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/groups/{GroupName}",
                                  validator: validate_GetGroup_599961, base: "/",
                                  url: url_GetGroup_599962,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_600005 = ref object of OpenApiRestCall_599368
proc url_DeleteGroup_600007(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_600006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600008 = path.getOrDefault("GroupName")
  valid_600008 = validateParameter(valid_600008, JString, required = true,
                                 default = nil)
  if valid_600008 != nil:
    section.add "GroupName", valid_600008
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
  var valid_600009 = header.getOrDefault("X-Amz-Date")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Date", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Security-Token")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Security-Token", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Content-Sha256", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Algorithm")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Algorithm", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Signature")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Signature", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-SignedHeaders", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Credential")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Credential", valid_600015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DeleteGroup_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DeleteGroup_600005; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   GroupName: string (required)
  ##            : The name of the resource group to delete.
  var path_600018 = newJObject()
  add(path_600018, "GroupName", newJString(GroupName))
  result = call_600017.call(path_600018, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_600005(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_DeleteGroup_600006,
                                        base: "/", url: url_DeleteGroup_600007,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_600033 = ref object of OpenApiRestCall_599368
proc url_UpdateGroupQuery_600035(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroupQuery_600034(path: JsonNode; query: JsonNode;
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
  var valid_600036 = path.getOrDefault("GroupName")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = nil)
  if valid_600036 != nil:
    section.add "GroupName", valid_600036
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_UpdateGroupQuery_600033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource query of a group.
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_UpdateGroupQuery_600033; GroupName: string;
          body: JsonNode): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to edit the query.
  ##   body: JObject (required)
  var path_600047 = newJObject()
  var body_600048 = newJObject()
  add(path_600047, "GroupName", newJString(GroupName))
  if body != nil:
    body_600048 = body
  result = call_600046.call(path_600047, nil, nil, nil, body_600048)

var updateGroupQuery* = Call_UpdateGroupQuery_600033(name: "updateGroupQuery",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_UpdateGroupQuery_600034,
    base: "/", url: url_UpdateGroupQuery_600035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_600019 = ref object of OpenApiRestCall_599368
proc url_GetGroupQuery_600021(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupQuery_600020(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600022 = path.getOrDefault("GroupName")
  valid_600022 = validateParameter(valid_600022, JString, required = true,
                                 default = nil)
  if valid_600022 != nil:
    section.add "GroupName", valid_600022
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
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600030: Call_GetGroupQuery_600019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the resource query associated with the specified resource group.
  ## 
  let valid = call_600030.validator(path, query, header, formData, body)
  let scheme = call_600030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600030.url(scheme.get, call_600030.host, call_600030.base,
                         call_600030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600030, url, valid)

proc call*(call_600031: Call_GetGroupQuery_600019; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_600032 = newJObject()
  add(path_600032, "GroupName", newJString(GroupName))
  result = call_600031.call(path_600032, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_600019(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_600020,
    base: "/", url: url_GetGroupQuery_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_600063 = ref object of OpenApiRestCall_599368
proc url_Tag_600065(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Tag_600064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600066 = path.getOrDefault("Arn")
  valid_600066 = validateParameter(valid_600066, JString, required = true,
                                 default = nil)
  if valid_600066 != nil:
    section.add "Arn", valid_600066
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Content-Sha256", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Algorithm")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Algorithm", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Signature")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Signature", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-SignedHeaders", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Credential")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Credential", valid_600073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600075: Call_Tag_600063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_600075.validator(path, query, header, formData, body)
  let scheme = call_600075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600075.url(scheme.get, call_600075.host, call_600075.base,
                         call_600075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600075, url, valid)

proc call*(call_600076: Call_Tag_600063; Arn: string; body: JsonNode): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   Arn: string (required)
  ##      : The ARN of the resource to which to add tags.
  ##   body: JObject (required)
  var path_600077 = newJObject()
  var body_600078 = newJObject()
  add(path_600077, "Arn", newJString(Arn))
  if body != nil:
    body_600078 = body
  result = call_600076.call(path_600077, nil, nil, nil, body_600078)

var tag* = Call_Tag_600063(name: "tag", meth: HttpMethod.HttpPut,
                        host: "resource-groups.amazonaws.com",
                        route: "/resources/{Arn}/tags", validator: validate_Tag_600064,
                        base: "/", url: url_Tag_600065,
                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_600049 = ref object of OpenApiRestCall_599368
proc url_GetTags_600051(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_600050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600052 = path.getOrDefault("Arn")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = nil)
  if valid_600052 != nil:
    section.add "Arn", valid_600052
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600060: Call_GetTags_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  let valid = call_600060.validator(path, query, header, formData, body)
  let scheme = call_600060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600060.url(scheme.get, call_600060.host, call_600060.base,
                         call_600060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600060, url, valid)

proc call*(call_600061: Call_GetTags_600049; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   Arn: string (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  var path_600062 = newJObject()
  add(path_600062, "Arn", newJString(Arn))
  result = call_600061.call(path_600062, nil, nil, nil, nil)

var getTags* = Call_GetTags_600049(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "resource-groups.amazonaws.com",
                                route: "/resources/{Arn}/tags",
                                validator: validate_GetTags_600050, base: "/",
                                url: url_GetTags_600051,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_600079 = ref object of OpenApiRestCall_599368
proc url_Untag_600081(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Untag_600080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600082 = path.getOrDefault("Arn")
  valid_600082 = validateParameter(valid_600082, JString, required = true,
                                 default = nil)
  if valid_600082 != nil:
    section.add "Arn", valid_600082
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_Untag_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a specified resource.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_Untag_600079; Arn: string; body: JsonNode): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   Arn: string (required)
  ##      : The ARN of the resource from which to remove tags.
  ##   body: JObject (required)
  var path_600093 = newJObject()
  var body_600094 = newJObject()
  add(path_600093, "Arn", newJString(Arn))
  if body != nil:
    body_600094 = body
  result = call_600092.call(path_600093, nil, nil, nil, body_600094)

var untag* = Call_Untag_600079(name: "untag", meth: HttpMethod.HttpPatch,
                            host: "resource-groups.amazonaws.com",
                            route: "/resources/{Arn}/tags",
                            validator: validate_Untag_600080, base: "/",
                            url: url_Untag_600081,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_600095 = ref object of OpenApiRestCall_599368
proc url_ListGroupResources_600097(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupResources_600096(path: JsonNode; query: JsonNode;
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
  var valid_600098 = path.getOrDefault("GroupName")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = nil)
  if valid_600098 != nil:
    section.add "GroupName", valid_600098
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
  var valid_600099 = query.getOrDefault("NextToken")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "NextToken", valid_600099
  var valid_600100 = query.getOrDefault("maxResults")
  valid_600100 = validateParameter(valid_600100, JInt, required = false, default = nil)
  if valid_600100 != nil:
    section.add "maxResults", valid_600100
  var valid_600101 = query.getOrDefault("nextToken")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "nextToken", valid_600101
  var valid_600102 = query.getOrDefault("MaxResults")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "MaxResults", valid_600102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600103 = header.getOrDefault("X-Amz-Date")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Date", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Security-Token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Security-Token", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Content-Sha256", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Algorithm")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Algorithm", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Signature", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-SignedHeaders", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Credential")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Credential", valid_600109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600111: Call_ListGroupResources_600095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  let valid = call_600111.validator(path, query, header, formData, body)
  let scheme = call_600111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600111.url(scheme.get, call_600111.host, call_600111.base,
                         call_600111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600111, url, valid)

proc call*(call_600112: Call_ListGroupResources_600095; GroupName: string;
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
  var path_600113 = newJObject()
  var query_600114 = newJObject()
  var body_600115 = newJObject()
  add(path_600113, "GroupName", newJString(GroupName))
  add(query_600114, "NextToken", newJString(NextToken))
  add(query_600114, "maxResults", newJInt(maxResults))
  add(query_600114, "nextToken", newJString(nextToken))
  if body != nil:
    body_600115 = body
  add(query_600114, "MaxResults", newJString(MaxResults))
  result = call_600112.call(path_600113, query_600114, nil, nil, body_600115)

var listGroupResources* = Call_ListGroupResources_600095(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_600096, base: "/",
    url: url_ListGroupResources_600097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_600116 = ref object of OpenApiRestCall_599368
proc url_ListGroups_600118(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_600117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600119 = query.getOrDefault("NextToken")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "NextToken", valid_600119
  var valid_600120 = query.getOrDefault("maxResults")
  valid_600120 = validateParameter(valid_600120, JInt, required = false, default = nil)
  if valid_600120 != nil:
    section.add "maxResults", valid_600120
  var valid_600121 = query.getOrDefault("nextToken")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "nextToken", valid_600121
  var valid_600122 = query.getOrDefault("MaxResults")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "MaxResults", valid_600122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600123 = header.getOrDefault("X-Amz-Date")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Date", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Security-Token")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Security-Token", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Content-Sha256", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Algorithm")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Algorithm", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Signature")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Signature", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-SignedHeaders", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Credential")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Credential", valid_600129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600131: Call_ListGroups_600116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing resource groups in your account.
  ## 
  let valid = call_600131.validator(path, query, header, formData, body)
  let scheme = call_600131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600131.url(scheme.get, call_600131.host, call_600131.base,
                         call_600131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600131, url, valid)

proc call*(call_600132: Call_ListGroups_600116; body: JsonNode;
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
  var query_600133 = newJObject()
  var body_600134 = newJObject()
  add(query_600133, "NextToken", newJString(NextToken))
  add(query_600133, "maxResults", newJInt(maxResults))
  add(query_600133, "nextToken", newJString(nextToken))
  if body != nil:
    body_600134 = body
  add(query_600133, "MaxResults", newJString(MaxResults))
  result = call_600132.call(nil, query_600133, nil, nil, body_600134)

var listGroups* = Call_ListGroups_600116(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/groups-list",
                                      validator: validate_ListGroups_600117,
                                      base: "/", url: url_ListGroups_600118,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_600135 = ref object of OpenApiRestCall_599368
proc url_SearchResources_600137(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchResources_600136(path: JsonNode; query: JsonNode;
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
  var valid_600138 = query.getOrDefault("NextToken")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "NextToken", valid_600138
  var valid_600139 = query.getOrDefault("MaxResults")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "MaxResults", valid_600139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600140 = header.getOrDefault("X-Amz-Date")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Date", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Security-Token")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Security-Token", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Content-Sha256", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Algorithm")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Algorithm", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Signature")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Signature", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-SignedHeaders", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Credential")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Credential", valid_600146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600148: Call_SearchResources_600135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  let valid = call_600148.validator(path, query, header, formData, body)
  let scheme = call_600148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600148.url(scheme.get, call_600148.host, call_600148.base,
                         call_600148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600148, url, valid)

proc call*(call_600149: Call_SearchResources_600135; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600150 = newJObject()
  var body_600151 = newJObject()
  add(query_600150, "NextToken", newJString(NextToken))
  if body != nil:
    body_600151 = body
  add(query_600150, "MaxResults", newJString(MaxResults))
  result = call_600149.call(nil, query_600150, nil, nil, body_600151)

var searchResources* = Call_SearchResources_600135(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_600136,
    base: "/", url: url_SearchResources_600137, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
