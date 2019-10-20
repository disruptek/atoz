
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_CreateLifecyclePolicy_592976 = ref object of OpenApiRestCall_592364
proc url_CreateLifecyclePolicy_592978(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLifecyclePolicy_592977(path: JsonNode; query: JsonNode;
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
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_CreateLifecyclePolicy_592976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_CreateLifecyclePolicy_592976; body: JsonNode): Recallable =
  ## createLifecyclePolicy
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ##   body: JObject (required)
  var body_592989 = newJObject()
  if body != nil:
    body_592989 = body
  result = call_592988.call(nil, nil, nil, nil, body_592989)

var createLifecyclePolicy* = Call_CreateLifecyclePolicy_592976(
    name: "createLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_CreateLifecyclePolicy_592977, base: "/",
    url: url_CreateLifecyclePolicy_592978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicies_592703 = ref object of OpenApiRestCall_592364
proc url_GetLifecyclePolicies_592705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicies_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = query.getOrDefault("tagsToAdd")
  valid_592817 = validateParameter(valid_592817, JArray, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "tagsToAdd", valid_592817
  var valid_592831 = query.getOrDefault("state")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = newJString("ENABLED"))
  if valid_592831 != nil:
    section.add "state", valid_592831
  var valid_592832 = query.getOrDefault("resourceTypes")
  valid_592832 = validateParameter(valid_592832, JArray, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "resourceTypes", valid_592832
  var valid_592833 = query.getOrDefault("policyIds")
  valid_592833 = validateParameter(valid_592833, JArray, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "policyIds", valid_592833
  var valid_592834 = query.getOrDefault("targetTags")
  valid_592834 = validateParameter(valid_592834, JArray, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "targetTags", valid_592834
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
  var valid_592835 = header.getOrDefault("X-Amz-Signature")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Signature", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Content-Sha256", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Date")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Date", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Credential")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Credential", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Security-Token")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Security-Token", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Algorithm")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Algorithm", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-SignedHeaders", valid_592841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592864: Call_GetLifecyclePolicies_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  let valid = call_592864.validator(path, query, header, formData, body)
  let scheme = call_592864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592864.url(scheme.get, call_592864.host, call_592864.base,
                         call_592864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592864, url, valid)

proc call*(call_592935: Call_GetLifecyclePolicies_592703;
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
  var query_592936 = newJObject()
  if tagsToAdd != nil:
    query_592936.add "tagsToAdd", tagsToAdd
  add(query_592936, "state", newJString(state))
  if resourceTypes != nil:
    query_592936.add "resourceTypes", resourceTypes
  if policyIds != nil:
    query_592936.add "policyIds", policyIds
  if targetTags != nil:
    query_592936.add "targetTags", targetTags
  result = call_592935.call(nil, query_592936, nil, nil, nil)

var getLifecyclePolicies* = Call_GetLifecyclePolicies_592703(
    name: "getLifecyclePolicies", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_GetLifecyclePolicies_592704, base: "/",
    url: url_GetLifecyclePolicies_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_592990 = ref object of OpenApiRestCall_592364
proc url_GetLifecyclePolicy_592992(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetLifecyclePolicy_592991(path: JsonNode; query: JsonNode;
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
  var valid_593007 = path.getOrDefault("policyId")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "policyId", valid_593007
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
  var valid_593008 = header.getOrDefault("X-Amz-Signature")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Signature", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Content-Sha256", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Date")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Date", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Credential")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Credential", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Security-Token")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Security-Token", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Algorithm")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Algorithm", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-SignedHeaders", valid_593014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_GetLifecyclePolicy_592990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_GetLifecyclePolicy_592990; policyId: string): Recallable =
  ## getLifecyclePolicy
  ## Gets detailed information about the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_593017 = newJObject()
  add(path_593017, "policyId", newJString(policyId))
  result = call_593016.call(path_593017, nil, nil, nil, nil)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_592990(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpGet, host: "dlm.amazonaws.com",
    route: "/policies/{policyId}/", validator: validate_GetLifecyclePolicy_592991,
    base: "/", url: url_GetLifecyclePolicy_592992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_593018 = ref object of OpenApiRestCall_592364
proc url_DeleteLifecyclePolicy_593020(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteLifecyclePolicy_593019(path: JsonNode; query: JsonNode;
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
  var valid_593021 = path.getOrDefault("policyId")
  valid_593021 = validateParameter(valid_593021, JString, required = true,
                                 default = nil)
  if valid_593021 != nil:
    section.add "policyId", valid_593021
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
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_DeleteLifecyclePolicy_593018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_DeleteLifecyclePolicy_593018; policyId: string): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_593031 = newJObject()
  add(path_593031, "policyId", newJString(policyId))
  result = call_593030.call(path_593031, nil, nil, nil, nil)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_593018(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpDelete,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_DeleteLifecyclePolicy_593019, base: "/",
    url: url_DeleteLifecyclePolicy_593020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLifecyclePolicy_593032 = ref object of OpenApiRestCall_592364
proc url_UpdateLifecyclePolicy_593034(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateLifecyclePolicy_593033(path: JsonNode; query: JsonNode;
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
  var valid_593035 = path.getOrDefault("policyId")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = nil)
  if valid_593035 != nil:
    section.add "policyId", valid_593035
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
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_UpdateLifecyclePolicy_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified lifecycle policy.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_UpdateLifecyclePolicy_593032; policyId: string;
          body: JsonNode): Recallable =
  ## updateLifecyclePolicy
  ## Updates the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  ##   body: JObject (required)
  var path_593046 = newJObject()
  var body_593047 = newJObject()
  add(path_593046, "policyId", newJString(policyId))
  if body != nil:
    body_593047 = body
  result = call_593045.call(path_593046, nil, nil, nil, body_593047)

var updateLifecyclePolicy* = Call_UpdateLifecyclePolicy_593032(
    name: "updateLifecyclePolicy", meth: HttpMethod.HttpPatch,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}",
    validator: validate_UpdateLifecyclePolicy_593033, base: "/",
    url: url_UpdateLifecyclePolicy_593034, schemes: {Scheme.Https, Scheme.Http})
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
