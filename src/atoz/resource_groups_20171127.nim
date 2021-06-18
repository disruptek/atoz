
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "resource-groups.ap-northeast-1.amazonaws.com", "ap-southeast-1": "resource-groups.ap-southeast-1.amazonaws.com", "us-west-2": "resource-groups.us-west-2.amazonaws.com", "eu-west-2": "resource-groups.eu-west-2.amazonaws.com", "ap-northeast-3": "resource-groups.ap-northeast-3.amazonaws.com", "eu-central-1": "resource-groups.eu-central-1.amazonaws.com", "us-east-2": "resource-groups.us-east-2.amazonaws.com", "us-east-1": "resource-groups.us-east-1.amazonaws.com", "cn-northwest-1": "resource-groups.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "resource-groups.ap-south-1.amazonaws.com", "eu-north-1": "resource-groups.eu-north-1.amazonaws.com", "ap-northeast-2": "resource-groups.ap-northeast-2.amazonaws.com", "us-west-1": "resource-groups.us-west-1.amazonaws.com", "us-gov-east-1": "resource-groups.us-gov-east-1.amazonaws.com", "eu-west-3": "resource-groups.eu-west-3.amazonaws.com", "cn-north-1": "resource-groups.cn-north-1.amazonaws.com.cn", "sa-east-1": "resource-groups.sa-east-1.amazonaws.com", "eu-west-1": "resource-groups.eu-west-1.amazonaws.com", "us-gov-west-1": "resource-groups.us-gov-west-1.amazonaws.com", "ap-southeast-2": "resource-groups.ap-southeast-2.amazonaws.com", "ca-central-1": "resource-groups.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateGroup_402656288 = ref object of OpenApiRestCall_402656038
proc url_CreateGroup_402656290(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_402656289(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a group with a specified name, description, and resource query.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Security-Token", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Signature")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Signature", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Algorithm", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Date")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Date", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Credential")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Credential", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656393: Call_CreateGroup_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a group with a specified name, description, and resource query.
                                                                                         ## 
  let valid = call_402656393.validator(path, query, header, formData, body, _)
  let scheme = call_402656393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656393.makeUrl(scheme.get, call_402656393.host, call_402656393.base,
                                   call_402656393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656393, uri, valid, _)

proc call*(call_402656442: Call_CreateGroup_402656288; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   
                                                                            ## body: JObject (required)
  var body_402656443 = newJObject()
  if body != nil:
    body_402656443 = body
  result = call_402656442.call(nil, nil, nil, nil, body_402656443)

var createGroup* = Call_CreateGroup_402656288(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/groups", validator: validate_CreateGroup_402656289, base: "/",
    makeUrl: url_CreateGroup_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_402656495 = ref object of OpenApiRestCall_402656038
proc url_UpdateGroup_402656497(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_402656496(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group for which you want to update its description.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656498 = path.getOrDefault("GroupName")
  valid_402656498 = validateParameter(valid_402656498, JString, required = true,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "GroupName", valid_402656498
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656499 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Security-Token", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Signature")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Signature", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Algorithm", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Date")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Date", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Credential")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Credential", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656507: Call_UpdateGroup_402656495; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_UpdateGroup_402656495; body: JsonNode;
           GroupName: string): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   
                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                            ## GroupName: string (required)
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## The 
                                                                                                                                            ## name 
                                                                                                                                            ## of 
                                                                                                                                            ## the 
                                                                                                                                            ## resource 
                                                                                                                                            ## group 
                                                                                                                                            ## for 
                                                                                                                                            ## which 
                                                                                                                                            ## you 
                                                                                                                                            ## want 
                                                                                                                                            ## to 
                                                                                                                                            ## update 
                                                                                                                                            ## its 
                                                                                                                                            ## description.
  var path_402656509 = newJObject()
  var body_402656510 = newJObject()
  if body != nil:
    body_402656510 = body
  add(path_402656509, "GroupName", newJString(GroupName))
  result = call_402656508.call(path_402656509, nil, nil, nil, body_402656510)

var updateGroup* = Call_UpdateGroup_402656495(name: "updateGroup",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}", validator: validate_UpdateGroup_402656496,
    base: "/", makeUrl: url_UpdateGroup_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_402656470 = ref object of OpenApiRestCall_402656038
proc url_GetGroup_402656472(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroup_402656471(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specified resource group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656484 = path.getOrDefault("GroupName")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "GroupName", valid_402656484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656492: Call_GetGroup_402656470; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified resource group.
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_GetGroup_402656470; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
                                                          ##            : The name of the resource group.
  var path_402656494 = newJObject()
  add(path_402656494, "GroupName", newJString(GroupName))
  result = call_402656493.call(path_402656494, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_402656470(name: "getGroup",
                                        meth: HttpMethod.HttpGet,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_GetGroup_402656471,
                                        base: "/", makeUrl: url_GetGroup_402656472,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_402656511 = ref object of OpenApiRestCall_402656038
proc url_DeleteGroup_402656513(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_402656512(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656514 = path.getOrDefault("GroupName")
  valid_402656514 = validateParameter(valid_402656514, JString, required = true,
                                      default = nil)
  if valid_402656514 != nil:
    section.add "GroupName", valid_402656514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656522: Call_DeleteGroup_402656511; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_DeleteGroup_402656511; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   
                                                                                                                                                                ## GroupName: string (required)
                                                                                                                                                                ##            
                                                                                                                                                                ## : 
                                                                                                                                                                ## The 
                                                                                                                                                                ## name 
                                                                                                                                                                ## of 
                                                                                                                                                                ## the 
                                                                                                                                                                ## resource 
                                                                                                                                                                ## group 
                                                                                                                                                                ## to 
                                                                                                                                                                ## delete.
  var path_402656524 = newJObject()
  add(path_402656524, "GroupName", newJString(GroupName))
  result = call_402656523.call(path_402656524, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_402656511(name: "deleteGroup",
    meth: HttpMethod.HttpDelete, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}", validator: validate_DeleteGroup_402656512,
    base: "/", makeUrl: url_DeleteGroup_402656513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_402656539 = ref object of OpenApiRestCall_402656038
proc url_UpdateGroupQuery_402656541(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateGroupQuery_402656540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the resource query of a group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group for which you want to edit the query.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656542 = path.getOrDefault("GroupName")
  valid_402656542 = validateParameter(valid_402656542, JString, required = true,
                                      default = nil)
  if valid_402656542 != nil:
    section.add "GroupName", valid_402656542
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656543 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Security-Token", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Signature")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Signature", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Algorithm", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Date")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Date", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Credential")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Credential", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656551: Call_UpdateGroupQuery_402656539;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the resource query of a group.
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_UpdateGroupQuery_402656539; body: JsonNode;
           GroupName: string): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   body: JObject (required)
  ##   GroupName: string (required)
                               ##            : The name of the resource group for which you want to edit the query.
  var path_402656553 = newJObject()
  var body_402656554 = newJObject()
  if body != nil:
    body_402656554 = body
  add(path_402656553, "GroupName", newJString(GroupName))
  result = call_402656552.call(path_402656553, nil, nil, nil, body_402656554)

var updateGroupQuery* = Call_UpdateGroupQuery_402656539(
    name: "updateGroupQuery", meth: HttpMethod.HttpPut,
    host: "resource-groups.amazonaws.com", route: "/groups/{GroupName}/query",
    validator: validate_UpdateGroupQuery_402656540, base: "/",
    makeUrl: url_UpdateGroupQuery_402656541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_402656525 = ref object of OpenApiRestCall_402656038
proc url_GetGroupQuery_402656527(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupQuery_402656526(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the resource query associated with the specified resource group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656528 = path.getOrDefault("GroupName")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true,
                                      default = nil)
  if valid_402656528 != nil:
    section.add "GroupName", valid_402656528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656536: Call_GetGroupQuery_402656525; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the resource query associated with the specified resource group.
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_GetGroupQuery_402656525; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   
                                                                             ## GroupName: string (required)
                                                                             ##            
                                                                             ## : 
                                                                             ## The 
                                                                             ## name 
                                                                             ## of 
                                                                             ## the 
                                                                             ## resource 
                                                                             ## group.
  var path_402656538 = newJObject()
  add(path_402656538, "GroupName", newJString(GroupName))
  result = call_402656537.call(path_402656538, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_402656525(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_402656526,
    base: "/", makeUrl: url_GetGroupQuery_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_402656569 = ref object of OpenApiRestCall_402656038
proc url_Tag_402656571(protocol: Scheme; host: string; base: string;
                       route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_Tag_402656570(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
                                 ##      : The ARN of the resource to which to add tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_402656572 = path.getOrDefault("Arn")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "Arn", valid_402656572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656581: Call_Tag_402656569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_Tag_402656569; Arn: string; body: JsonNode): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   
                                                                                                                                                                 ## Arn: string (required)
                                                                                                                                                                 ##      
                                                                                                                                                                 ## : 
                                                                                                                                                                 ## The 
                                                                                                                                                                 ## ARN 
                                                                                                                                                                 ## of 
                                                                                                                                                                 ## the 
                                                                                                                                                                 ## resource 
                                                                                                                                                                 ## to 
                                                                                                                                                                 ## which 
                                                                                                                                                                 ## to 
                                                                                                                                                                 ## add 
                                                                                                                                                                 ## tags.
  ##   
                                                                                                                                                                         ## body: JObject (required)
  var path_402656583 = newJObject()
  var body_402656584 = newJObject()
  add(path_402656583, "Arn", newJString(Arn))
  if body != nil:
    body_402656584 = body
  result = call_402656582.call(path_402656583, nil, nil, nil, body_402656584)

var tag* = Call_Tag_402656569(name: "tag", meth: HttpMethod.HttpPut,
                              host: "resource-groups.amazonaws.com",
                              route: "/resources/{Arn}/tags",
                              validator: validate_Tag_402656570, base: "/",
                              makeUrl: url_Tag_402656571,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_402656555 = ref object of OpenApiRestCall_402656038
proc url_GetTags_402656557(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetTags_402656556(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
                                 ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_402656558 = path.getOrDefault("Arn")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true,
                                      default = nil)
  if valid_402656558 != nil:
    section.add "Arn", valid_402656558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_GetTags_402656555; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_GetTags_402656555; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   
                                                                                           ## Arn: string (required)
                                                                                           ##      
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## ARN 
                                                                                           ## of 
                                                                                           ## the 
                                                                                           ## resource 
                                                                                           ## group 
                                                                                           ## for 
                                                                                           ## which 
                                                                                           ## you 
                                                                                           ## want 
                                                                                           ## a 
                                                                                           ## list 
                                                                                           ## of 
                                                                                           ## tags. 
                                                                                           ## The 
                                                                                           ## resource 
                                                                                           ## must 
                                                                                           ## exist 
                                                                                           ## within 
                                                                                           ## the 
                                                                                           ## account 
                                                                                           ## you 
                                                                                           ## are 
                                                                                           ## using.
  var path_402656568 = newJObject()
  add(path_402656568, "Arn", newJString(Arn))
  result = call_402656567.call(path_402656568, nil, nil, nil, nil)

var getTags* = Call_GetTags_402656555(name: "getTags", meth: HttpMethod.HttpGet,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/resources/{Arn}/tags",
                                      validator: validate_GetTags_402656556,
                                      base: "/", makeUrl: url_GetTags_402656557,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_402656585 = ref object of OpenApiRestCall_402656038
proc url_Untag_402656587(protocol: Scheme; host: string; base: string;
                         route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_Untag_402656586(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes specified tags from a specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
                                 ##      : The ARN of the resource from which to remove tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_402656588 = path.getOrDefault("Arn")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true,
                                      default = nil)
  if valid_402656588 != nil:
    section.add "Arn", valid_402656588
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656589 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Security-Token", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Signature")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Signature", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Algorithm", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Date")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Date", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Credential")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Credential", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656597: Call_Untag_402656585; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a specified resource.
                                                                                         ## 
  let valid = call_402656597.validator(path, query, header, formData, body, _)
  let scheme = call_402656597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656597.makeUrl(scheme.get, call_402656597.host, call_402656597.base,
                                   call_402656597.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656597, uri, valid, _)

proc call*(call_402656598: Call_Untag_402656585; Arn: string; body: JsonNode): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   Arn: string (required)
                                                      ##      : The ARN of the resource from which to remove tags.
  ##   
                                                                                                                  ## body: JObject (required)
  var path_402656599 = newJObject()
  var body_402656600 = newJObject()
  add(path_402656599, "Arn", newJString(Arn))
  if body != nil:
    body_402656600 = body
  result = call_402656598.call(path_402656599, nil, nil, nil, body_402656600)

var untag* = Call_Untag_402656585(name: "untag", meth: HttpMethod.HttpPatch,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/resources/{Arn}/tags",
                                  validator: validate_Untag_402656586,
                                  base: "/", makeUrl: url_Untag_402656587,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_402656601 = ref object of OpenApiRestCall_402656038
proc url_ListGroupResources_402656603(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListGroupResources_402656602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
                                 ##            : The name of the resource group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupName` field"
  var valid_402656604 = path.getOrDefault("GroupName")
  valid_402656604 = validateParameter(valid_402656604, JString, required = true,
                                      default = nil)
  if valid_402656604 != nil:
    section.add "GroupName", valid_402656604
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  ##   
                                                                                                                                                                                                        ## nextToken: JString
                                                                                                                                                                                                        ##            
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                        ## NextToken 
                                                                                                                                                                                                        ## value 
                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                        ## is 
                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                        ## paginated 
                                                                                                                                                                                                        ## ListGroupResources 
                                                                                                                                                                                                        ## request. 
                                                                                                                                                                                                        ## To 
                                                                                                                                                                                                        ## get 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## next 
                                                                                                                                                                                                        ## page 
                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                        ## results, 
                                                                                                                                                                                                        ## run 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## call 
                                                                                                                                                                                                        ## again, 
                                                                                                                                                                                                        ## add 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## NextToken 
                                                                                                                                                                                                        ## parameter, 
                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                        ## specify 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## NextToken 
                                                                                                                                                                                                        ## value.
  ##   
                                                                                                                                                                                                                 ## MaxResults: JString
                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                         ## NextToken: JString
                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                         ## token
  section = newJObject()
  var valid_402656605 = query.getOrDefault("maxResults")
  valid_402656605 = validateParameter(valid_402656605, JInt, required = false,
                                      default = nil)
  if valid_402656605 != nil:
    section.add "maxResults", valid_402656605
  var valid_402656606 = query.getOrDefault("nextToken")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "nextToken", valid_402656606
  var valid_402656607 = query.getOrDefault("MaxResults")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "MaxResults", valid_402656607
  var valid_402656608 = query.getOrDefault("NextToken")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "NextToken", valid_402656608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Security-Token", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Signature")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Signature", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Algorithm", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Date")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Date", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Credential")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Credential", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656617: Call_ListGroupResources_402656601;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
                                                                                         ## 
  let valid = call_402656617.validator(path, query, header, formData, body, _)
  let scheme = call_402656617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656617.makeUrl(scheme.get, call_402656617.host, call_402656617.base,
                                   call_402656617.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656617, uri, valid, _)

proc call*(call_402656618: Call_ListGroupResources_402656601; body: JsonNode;
           GroupName: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupResources
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ##   
                                                                                        ## maxResults: int
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## maximum 
                                                                                        ## number 
                                                                                        ## of 
                                                                                        ## group 
                                                                                        ## member 
                                                                                        ## ARNs 
                                                                                        ## that 
                                                                                        ## are 
                                                                                        ## returned 
                                                                                        ## in 
                                                                                        ## a 
                                                                                        ## single 
                                                                                        ## call 
                                                                                        ## by 
                                                                                        ## ListGroupResources, 
                                                                                        ## in 
                                                                                        ## paginated 
                                                                                        ## output. 
                                                                                        ## By 
                                                                                        ## default, 
                                                                                        ## this 
                                                                                        ## number 
                                                                                        ## is 
                                                                                        ## 50.
  ##   
                                                                                              ## nextToken: string
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## NextToken 
                                                                                              ## value 
                                                                                              ## that 
                                                                                              ## is 
                                                                                              ## returned 
                                                                                              ## in 
                                                                                              ## a 
                                                                                              ## paginated 
                                                                                              ## ListGroupResources 
                                                                                              ## request. 
                                                                                              ## To 
                                                                                              ## get 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## page 
                                                                                              ## of 
                                                                                              ## results, 
                                                                                              ## run 
                                                                                              ## the 
                                                                                              ## call 
                                                                                              ## again, 
                                                                                              ## add 
                                                                                              ## the 
                                                                                              ## NextToken 
                                                                                              ## parameter, 
                                                                                              ## and 
                                                                                              ## specify 
                                                                                              ## the 
                                                                                              ## NextToken 
                                                                                              ## value.
  ##   
                                                                                                       ## MaxResults: string
                                                                                                       ##             
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## limit
  ##   
                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                          ## NextToken: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## token
  ##   
                                                                                                                                                  ## GroupName: string (required)
                                                                                                                                                  ##            
                                                                                                                                                  ## : 
                                                                                                                                                  ## The 
                                                                                                                                                  ## name 
                                                                                                                                                  ## of 
                                                                                                                                                  ## the 
                                                                                                                                                  ## resource 
                                                                                                                                                  ## group.
  var path_402656619 = newJObject()
  var query_402656620 = newJObject()
  var body_402656621 = newJObject()
  add(query_402656620, "maxResults", newJInt(maxResults))
  add(query_402656620, "nextToken", newJString(nextToken))
  add(query_402656620, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656621 = body
  add(query_402656620, "NextToken", newJString(NextToken))
  add(path_402656619, "GroupName", newJString(GroupName))
  result = call_402656618.call(path_402656619, query_402656620, nil, nil, body_402656621)

var listGroupResources* = Call_ListGroupResources_402656601(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_402656602, base: "/",
    makeUrl: url_ListGroupResources_402656603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_402656622 = ref object of OpenApiRestCall_402656038
proc url_ListGroups_402656624(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_402656623(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing resource groups in your account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   
                                                                                                                                                                                   ## nextToken: JString
                                                                                                                                                                                   ##            
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## The 
                                                                                                                                                                                   ## NextToken 
                                                                                                                                                                                   ## value 
                                                                                                                                                                                   ## that 
                                                                                                                                                                                   ## is 
                                                                                                                                                                                   ## returned 
                                                                                                                                                                                   ## in 
                                                                                                                                                                                   ## a 
                                                                                                                                                                                   ## paginated 
                                                                                                                                                                                   ## <code>ListGroups</code> 
                                                                                                                                                                                   ## request. 
                                                                                                                                                                                   ## To 
                                                                                                                                                                                   ## get 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## next 
                                                                                                                                                                                   ## page 
                                                                                                                                                                                   ## of 
                                                                                                                                                                                   ## results, 
                                                                                                                                                                                   ## run 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## call 
                                                                                                                                                                                   ## again, 
                                                                                                                                                                                   ## add 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## NextToken 
                                                                                                                                                                                   ## parameter, 
                                                                                                                                                                                   ## and 
                                                                                                                                                                                   ## specify 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## NextToken 
                                                                                                                                                                                   ## value.
  ##   
                                                                                                                                                                                            ## MaxResults: JString
                                                                                                                                                                                            ##             
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                    ## NextToken: JString
                                                                                                                                                                                                    ##            
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                    ## token
  section = newJObject()
  var valid_402656625 = query.getOrDefault("maxResults")
  valid_402656625 = validateParameter(valid_402656625, JInt, required = false,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "maxResults", valid_402656625
  var valid_402656626 = query.getOrDefault("nextToken")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "nextToken", valid_402656626
  var valid_402656627 = query.getOrDefault("MaxResults")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "MaxResults", valid_402656627
  var valid_402656628 = query.getOrDefault("NextToken")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "NextToken", valid_402656628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656629 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Security-Token", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Signature")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Signature", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Algorithm", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Date")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Date", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Credential")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Credential", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656637: Call_ListGroups_402656622; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing resource groups in your account.
                                                                                         ## 
  let valid = call_402656637.validator(path, query, header, formData, body, _)
  let scheme = call_402656637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656637.makeUrl(scheme.get, call_402656637.host, call_402656637.base,
                                   call_402656637.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656637, uri, valid, _)

proc call*(call_402656638: Call_ListGroups_402656622; body: JsonNode;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listGroups
  ## Returns a list of existing resource groups in your account.
  ##   maxResults: int
                                                                ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   
                                                                                                                                                                                                                 ## nextToken: string
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                 ## is 
                                                                                                                                                                                                                 ## returned 
                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                 ## paginated 
                                                                                                                                                                                                                 ## <code>ListGroups</code> 
                                                                                                                                                                                                                 ## request. 
                                                                                                                                                                                                                 ## To 
                                                                                                                                                                                                                 ## get 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## next 
                                                                                                                                                                                                                 ## page 
                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                 ## results, 
                                                                                                                                                                                                                 ## run 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                                 ## again, 
                                                                                                                                                                                                                 ## add 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                                 ## parameter, 
                                                                                                                                                                                                                 ## and 
                                                                                                                                                                                                                 ## specify 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                                 ## value.
  ##   
                                                                                                                                                                                                                          ## MaxResults: string
                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                          ## limit
  ##   
                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                             ## NextToken: string
                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                             ## token
  var query_402656639 = newJObject()
  var body_402656640 = newJObject()
  add(query_402656639, "maxResults", newJInt(maxResults))
  add(query_402656639, "nextToken", newJString(nextToken))
  add(query_402656639, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656640 = body
  add(query_402656639, "NextToken", newJString(NextToken))
  result = call_402656638.call(nil, query_402656639, nil, nil, body_402656640)

var listGroups* = Call_ListGroups_402656622(name: "listGroups",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/groups-list", validator: validate_ListGroups_402656623, base: "/",
    makeUrl: url_ListGroups_402656624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_402656641 = ref object of OpenApiRestCall_402656038
proc url_SearchResources_402656643(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchResources_402656642(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656644 = query.getOrDefault("MaxResults")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "MaxResults", valid_402656644
  var valid_402656645 = query.getOrDefault("NextToken")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "NextToken", valid_402656645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656646 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Security-Token", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Signature")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Signature", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Algorithm", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Date")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Date", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Credential")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Credential", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656654: Call_SearchResources_402656641; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
                                                                                         ## 
  let valid = call_402656654.validator(path, query, header, formData, body, _)
  let scheme = call_402656654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656654.makeUrl(scheme.get, call_402656654.host, call_402656654.base,
                                   call_402656654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656654, uri, valid, _)

proc call*(call_402656655: Call_SearchResources_402656641; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   
                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                  ##             
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                     ## token
  var query_402656656 = newJObject()
  var body_402656657 = newJObject()
  add(query_402656656, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656657 = body
  add(query_402656656, "NextToken", newJString(NextToken))
  result = call_402656655.call(nil, query_402656656, nil, nil, body_402656657)

var searchResources* = Call_SearchResources_402656641(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_402656642,
    base: "/", makeUrl: url_SearchResources_402656643,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}