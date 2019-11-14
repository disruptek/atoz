
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Data Lifecycle Manager
## version: 2018-01-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Data Lifecycle Manager</fullname> <p>With Amazon Data Lifecycle Manager, you can manage the lifecycle of your AWS resources. You create lifecycle policies, which are used to automate operations on the specified resources.</p> <p>Amazon DLM supports Amazon EBS volumes and snapshots. For information about using Amazon DLM with Amazon EBS, see <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snapshot-lifecycle.html">Automating the Amazon EBS Snapshot Lifecycle</a> in the <i>Amazon EC2 User Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dlm/
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dlm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dlm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dlm.us-west-2.amazonaws.com",
                           "eu-west-2": "dlm.eu-west-2.amazonaws.com", "ap-northeast-3": "dlm.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "dlm.eu-central-1.amazonaws.com",
                           "us-east-2": "dlm.us-east-2.amazonaws.com",
                           "us-east-1": "dlm.us-east-1.amazonaws.com", "cn-northwest-1": "dlm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "dlm.ap-south-1.amazonaws.com",
                           "eu-north-1": "dlm.eu-north-1.amazonaws.com", "ap-northeast-2": "dlm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dlm.us-west-1.amazonaws.com",
                           "us-gov-east-1": "dlm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dlm.eu-west-3.amazonaws.com",
                           "cn-north-1": "dlm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dlm.sa-east-1.amazonaws.com",
                           "eu-west-1": "dlm.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "dlm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dlm.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "dlm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dlm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dlm.ap-southeast-1.amazonaws.com",
      "us-west-2": "dlm.us-west-2.amazonaws.com",
      "eu-west-2": "dlm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dlm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dlm.eu-central-1.amazonaws.com",
      "us-east-2": "dlm.us-east-2.amazonaws.com",
      "us-east-1": "dlm.us-east-1.amazonaws.com",
      "cn-northwest-1": "dlm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dlm.ap-south-1.amazonaws.com",
      "eu-north-1": "dlm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dlm.ap-northeast-2.amazonaws.com",
      "us-west-1": "dlm.us-west-1.amazonaws.com",
      "us-gov-east-1": "dlm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dlm.eu-west-3.amazonaws.com",
      "cn-north-1": "dlm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dlm.sa-east-1.amazonaws.com",
      "eu-west-1": "dlm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dlm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dlm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dlm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dlm"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLifecyclePolicy_594000 = ref object of OpenApiRestCall_593389
proc url_CreateLifecyclePolicy_594002(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLifecyclePolicy_594001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
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
  var valid_594003 = header.getOrDefault("X-Amz-Signature")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Signature", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Content-Sha256", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Date")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Date", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Credential")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Credential", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Security-Token")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Security-Token", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Algorithm")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Algorithm", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-SignedHeaders", valid_594009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594011: Call_CreateLifecyclePolicy_594000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ## 
  let valid = call_594011.validator(path, query, header, formData, body)
  let scheme = call_594011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594011.url(scheme.get, call_594011.host, call_594011.base,
                         call_594011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594011, url, valid)

proc call*(call_594012: Call_CreateLifecyclePolicy_594000; body: JsonNode): Recallable =
  ## createLifecyclePolicy
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ##   body: JObject (required)
  var body_594013 = newJObject()
  if body != nil:
    body_594013 = body
  result = call_594012.call(nil, nil, nil, nil, body_594013)

var createLifecyclePolicy* = Call_CreateLifecyclePolicy_594000(
    name: "createLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_CreateLifecyclePolicy_594001, base: "/",
    url: url_CreateLifecyclePolicy_594002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicies_593727 = ref object of OpenApiRestCall_593389
proc url_GetLifecyclePolicies_593729(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLifecyclePolicies_593728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: JString
  ##        : The activation state.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  section = newJObject()
  var valid_593841 = query.getOrDefault("tagsToAdd")
  valid_593841 = validateParameter(valid_593841, JArray, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "tagsToAdd", valid_593841
  var valid_593855 = query.getOrDefault("state")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = newJString("ENABLED"))
  if valid_593855 != nil:
    section.add "state", valid_593855
  var valid_593856 = query.getOrDefault("resourceTypes")
  valid_593856 = validateParameter(valid_593856, JArray, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "resourceTypes", valid_593856
  var valid_593857 = query.getOrDefault("policyIds")
  valid_593857 = validateParameter(valid_593857, JArray, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "policyIds", valid_593857
  var valid_593858 = query.getOrDefault("targetTags")
  valid_593858 = validateParameter(valid_593858, JArray, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "targetTags", valid_593858
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
  var valid_593859 = header.getOrDefault("X-Amz-Signature")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Signature", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Content-Sha256", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Date")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Date", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Credential")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Credential", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Security-Token")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Security-Token", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Algorithm")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Algorithm", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-SignedHeaders", valid_593865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593888: Call_GetLifecyclePolicies_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  let valid = call_593888.validator(path, query, header, formData, body)
  let scheme = call_593888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593888.url(scheme.get, call_593888.host, call_593888.base,
                         call_593888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593888, url, valid)

proc call*(call_593959: Call_GetLifecyclePolicies_593727;
          tagsToAdd: JsonNode = nil; state: string = "ENABLED";
          resourceTypes: JsonNode = nil; policyIds: JsonNode = nil;
          targetTags: JsonNode = nil): Recallable =
  ## getLifecyclePolicies
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: string
  ##        : The activation state.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  var query_593960 = newJObject()
  if tagsToAdd != nil:
    query_593960.add "tagsToAdd", tagsToAdd
  add(query_593960, "state", newJString(state))
  if resourceTypes != nil:
    query_593960.add "resourceTypes", resourceTypes
  if policyIds != nil:
    query_593960.add "policyIds", policyIds
  if targetTags != nil:
    query_593960.add "targetTags", targetTags
  result = call_593959.call(nil, query_593960, nil, nil, nil)

var getLifecyclePolicies* = Call_GetLifecyclePolicies_593727(
    name: "getLifecyclePolicies", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_GetLifecyclePolicies_593728, base: "/",
    url: url_GetLifecyclePolicies_593729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_594014 = ref object of OpenApiRestCall_593389
proc url_GetLifecyclePolicy_594016(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLifecyclePolicy_594015(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_594031 = path.getOrDefault("policyId")
  valid_594031 = validateParameter(valid_594031, JString, required = true,
                                 default = nil)
  if valid_594031 != nil:
    section.add "policyId", valid_594031
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
  var valid_594032 = header.getOrDefault("X-Amz-Signature")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Signature", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Content-Sha256", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Date")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Date", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Credential")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Credential", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Algorithm")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Algorithm", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-SignedHeaders", valid_594038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594039: Call_GetLifecyclePolicy_594014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  let valid = call_594039.validator(path, query, header, formData, body)
  let scheme = call_594039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594039.url(scheme.get, call_594039.host, call_594039.base,
                         call_594039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594039, url, valid)

proc call*(call_594040: Call_GetLifecyclePolicy_594014; policyId: string): Recallable =
  ## getLifecyclePolicy
  ## Gets detailed information about the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_594041 = newJObject()
  add(path_594041, "policyId", newJString(policyId))
  result = call_594040.call(path_594041, nil, nil, nil, nil)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_594014(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpGet, host: "dlm.amazonaws.com",
    route: "/policies/{policyId}/", validator: validate_GetLifecyclePolicy_594015,
    base: "/", url: url_GetLifecyclePolicy_594016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_594042 = ref object of OpenApiRestCall_593389
proc url_DeleteLifecyclePolicy_594044(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLifecyclePolicy_594043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_594045 = path.getOrDefault("policyId")
  valid_594045 = validateParameter(valid_594045, JString, required = true,
                                 default = nil)
  if valid_594045 != nil:
    section.add "policyId", valid_594045
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
  var valid_594046 = header.getOrDefault("X-Amz-Signature")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Signature", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Content-Sha256", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Date")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Date", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Credential")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Credential", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Security-Token")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Security-Token", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Algorithm")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Algorithm", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_DeleteLifecyclePolicy_594042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_DeleteLifecyclePolicy_594042; policyId: string): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_594055 = newJObject()
  add(path_594055, "policyId", newJString(policyId))
  result = call_594054.call(path_594055, nil, nil, nil, nil)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_594042(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpDelete,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_DeleteLifecyclePolicy_594043, base: "/",
    url: url_DeleteLifecyclePolicy_594044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594070 = ref object of OpenApiRestCall_593389
proc url_TagResource_594072(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_594071(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594073 = path.getOrDefault("resourceArn")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = nil)
  if valid_594073 != nil:
    section.add "resourceArn", valid_594073
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
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Content-Sha256", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Credential")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Credential", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Security-Token")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Security-Token", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Algorithm")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Algorithm", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-SignedHeaders", valid_594080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594082: Call_TagResource_594070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource.
  ## 
  let valid = call_594082.validator(path, query, header, formData, body)
  let scheme = call_594082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594082.url(scheme.get, call_594082.host, call_594082.base,
                         call_594082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594082, url, valid)

proc call*(call_594083: Call_TagResource_594070; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_594084 = newJObject()
  var body_594085 = newJObject()
  add(path_594084, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_594085 = body
  result = call_594083.call(path_594084, nil, nil, nil, body_594085)

var tagResource* = Call_TagResource_594070(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dlm.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594071,
                                        base: "/", url: url_TagResource_594072,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594056 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594058(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_594057(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594059 = path.getOrDefault("resourceArn")
  valid_594059 = validateParameter(valid_594059, JString, required = true,
                                 default = nil)
  if valid_594059 != nil:
    section.add "resourceArn", valid_594059
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
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Content-Sha256", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Credential")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Credential", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594067: Call_ListTagsForResource_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_594067.validator(path, query, header, formData, body)
  let scheme = call_594067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594067.url(scheme.get, call_594067.host, call_594067.base,
                         call_594067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594067, url, valid)

proc call*(call_594068: Call_ListTagsForResource_594056; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_594069 = newJObject()
  add(path_594069, "resourceArn", newJString(resourceArn))
  result = call_594068.call(path_594069, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594056(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594057, base: "/",
    url: url_ListTagsForResource_594058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594086 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594088(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_594087(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594089 = path.getOrDefault("resourceArn")
  valid_594089 = validateParameter(valid_594089, JString, required = true,
                                 default = nil)
  if valid_594089 != nil:
    section.add "resourceArn", valid_594089
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594090 = query.getOrDefault("tagKeys")
  valid_594090 = validateParameter(valid_594090, JArray, required = true, default = nil)
  if valid_594090 != nil:
    section.add "tagKeys", valid_594090
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
  var valid_594091 = header.getOrDefault("X-Amz-Signature")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Signature", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Content-Sha256", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Credential")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Credential", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Security-Token")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Security-Token", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_UntagResource_594086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_UntagResource_594086; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  var path_594100 = newJObject()
  var query_594101 = newJObject()
  add(path_594100, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_594101.add "tagKeys", tagKeys
  result = call_594099.call(path_594100, query_594101, nil, nil, nil)

var untagResource* = Call_UntagResource_594086(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dlm.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594087,
    base: "/", url: url_UntagResource_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLifecyclePolicy_594102 = ref object of OpenApiRestCall_593389
proc url_UpdateLifecyclePolicy_594104(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLifecyclePolicy_594103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified lifecycle policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_594105 = path.getOrDefault("policyId")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = nil)
  if valid_594105 != nil:
    section.add "policyId", valid_594105
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
  var valid_594106 = header.getOrDefault("X-Amz-Signature")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Signature", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Content-Sha256", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Date")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Date", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Credential")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Credential", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Algorithm")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Algorithm", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594114: Call_UpdateLifecyclePolicy_594102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified lifecycle policy.
  ## 
  let valid = call_594114.validator(path, query, header, formData, body)
  let scheme = call_594114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594114.url(scheme.get, call_594114.host, call_594114.base,
                         call_594114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594114, url, valid)

proc call*(call_594115: Call_UpdateLifecyclePolicy_594102; policyId: string;
          body: JsonNode): Recallable =
  ## updateLifecyclePolicy
  ## Updates the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  ##   body: JObject (required)
  var path_594116 = newJObject()
  var body_594117 = newJObject()
  add(path_594116, "policyId", newJString(policyId))
  if body != nil:
    body_594117 = body
  result = call_594115.call(path_594116, nil, nil, nil, body_594117)

var updateLifecyclePolicy* = Call_UpdateLifecyclePolicy_594102(
    name: "updateLifecyclePolicy", meth: HttpMethod.HttpPatch,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}",
    validator: validate_UpdateLifecyclePolicy_594103, base: "/",
    url: url_UpdateLifecyclePolicy_594104, schemes: {Scheme.Https, Scheme.Http})
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
