
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  awsServers = {Scheme.Https: {"ap-northeast-1": "dlm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dlm.ap-southeast-1.amazonaws.com",
                               "us-west-2": "dlm.us-west-2.amazonaws.com",
                               "eu-west-2": "dlm.eu-west-2.amazonaws.com", "ap-northeast-3": "dlm.ap-northeast-3.amazonaws.com", "eu-central-1": "dlm.eu-central-1.amazonaws.com",
                               "us-east-2": "dlm.us-east-2.amazonaws.com",
                               "us-east-1": "dlm.us-east-1.amazonaws.com", "cn-northwest-1": "dlm.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "dlm.ap-south-1.amazonaws.com",
                               "eu-north-1": "dlm.eu-north-1.amazonaws.com", "ap-northeast-2": "dlm.ap-northeast-2.amazonaws.com",
                               "us-west-1": "dlm.us-west-1.amazonaws.com", "us-gov-east-1": "dlm.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "dlm.eu-west-3.amazonaws.com",
                               "cn-north-1": "dlm.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "dlm.sa-east-1.amazonaws.com",
                               "eu-west-1": "dlm.eu-west-1.amazonaws.com", "us-gov-west-1": "dlm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dlm.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "dlm.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateLifecyclePolicy_402656486 = ref object of OpenApiRestCall_402656038
proc url_CreateLifecyclePolicy_402656488(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLifecyclePolicy_402656487(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
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
  var valid_402656489 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Security-Token", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Signature")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Signature", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Algorithm", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Date")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Date", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Credential")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Credential", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656495
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

proc call*(call_402656497: Call_CreateLifecyclePolicy_402656486;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
                                                                                         ## 
  let valid = call_402656497.validator(path, query, header, formData, body, _)
  let scheme = call_402656497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656497.makeUrl(scheme.get, call_402656497.host, call_402656497.base,
                                   call_402656497.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656497, uri, valid, _)

proc call*(call_402656498: Call_CreateLifecyclePolicy_402656486; body: JsonNode): Recallable =
  ## createLifecyclePolicy
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ##   
                                                                                                                          ## body: JObject (required)
  var body_402656499 = newJObject()
  if body != nil:
    body_402656499 = body
  result = call_402656498.call(nil, nil, nil, nil, body_402656499)

var createLifecyclePolicy* = Call_CreateLifecyclePolicy_402656486(
    name: "createLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_CreateLifecyclePolicy_402656487, base: "/",
    makeUrl: url_CreateLifecyclePolicy_402656488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicies_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetLifecyclePolicies_402656290(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLifecyclePolicies_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   state: JString
                                  ##        : The activation state.
  ##   
                                                                   ## resourceTypes: JArray
                                                                   ##                
                                                                   ## : 
                                                                   ## The resource type.
  ##   
                                                                                        ## targetTags: JArray
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## <p>The 
                                                                                        ## target 
                                                                                        ## tag 
                                                                                        ## for 
                                                                                        ## a 
                                                                                        ## policy.</p> 
                                                                                        ## <p>Tags 
                                                                                        ## are 
                                                                                        ## strings 
                                                                                        ## in 
                                                                                        ## the 
                                                                                        ## format 
                                                                                        ## <code>key=value</code>.</p>
  ##   
                                                                                                                      ## policyIds: JArray
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## identifiers 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## data 
                                                                                                                      ## lifecycle 
                                                                                                                      ## policies.
  ##   
                                                                                                                                  ## tagsToAdd: JArray
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## <p>The 
                                                                                                                                  ## tags 
                                                                                                                                  ## to 
                                                                                                                                  ## add 
                                                                                                                                  ## to 
                                                                                                                                  ## objects 
                                                                                                                                  ## created 
                                                                                                                                  ## by 
                                                                                                                                  ## the 
                                                                                                                                  ## policy.</p> 
                                                                                                                                  ## <p>Tags 
                                                                                                                                  ## are 
                                                                                                                                  ## strings 
                                                                                                                                  ## in 
                                                                                                                                  ## the 
                                                                                                                                  ## format 
                                                                                                                                  ## <code>key=value</code>.</p> 
                                                                                                                                  ## <p>These 
                                                                                                                                  ## user-defined 
                                                                                                                                  ## tags 
                                                                                                                                  ## are 
                                                                                                                                  ## added 
                                                                                                                                  ## in 
                                                                                                                                  ## addition 
                                                                                                                                  ## to 
                                                                                                                                  ## the 
                                                                                                                                  ## AWS-added 
                                                                                                                                  ## lifecycle 
                                                                                                                                  ## tags.</p>
  section = newJObject()
  var valid_402656381 = query.getOrDefault("state")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false,
                                      default = newJString("ENABLED"))
  if valid_402656381 != nil:
    section.add "state", valid_402656381
  var valid_402656382 = query.getOrDefault("resourceTypes")
  valid_402656382 = validateParameter(valid_402656382, JArray, required = false,
                                      default = nil)
  if valid_402656382 != nil:
    section.add "resourceTypes", valid_402656382
  var valid_402656383 = query.getOrDefault("targetTags")
  valid_402656383 = validateParameter(valid_402656383, JArray, required = false,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "targetTags", valid_402656383
  var valid_402656384 = query.getOrDefault("policyIds")
  valid_402656384 = validateParameter(valid_402656384, JArray, required = false,
                                      default = nil)
  if valid_402656384 != nil:
    section.add "policyIds", valid_402656384
  var valid_402656385 = query.getOrDefault("tagsToAdd")
  valid_402656385 = validateParameter(valid_402656385, JArray, required = false,
                                      default = nil)
  if valid_402656385 != nil:
    section.add "tagsToAdd", valid_402656385
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
  var valid_402656386 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Security-Token", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Signature")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Signature", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Algorithm", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Date")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Date", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Credential")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Credential", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656406: Call_GetLifecyclePolicies_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_GetLifecyclePolicies_402656288;
           state: string = "ENABLED"; resourceTypes: JsonNode = nil;
           targetTags: JsonNode = nil; policyIds: JsonNode = nil;
           tagsToAdd: JsonNode = nil): Recallable =
  ## getLifecyclePolicies
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ##   
                                                                                                                                                                          ## state: string
                                                                                                                                                                          ##        
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## activation 
                                                                                                                                                                          ## state.
  ##   
                                                                                                                                                                                   ## resourceTypes: JArray
                                                                                                                                                                                   ##                
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## The 
                                                                                                                                                                                   ## resource 
                                                                                                                                                                                   ## type.
  ##   
                                                                                                                                                                                           ## targetTags: JArray
                                                                                                                                                                                           ##             
                                                                                                                                                                                           ## : 
                                                                                                                                                                                           ## <p>The 
                                                                                                                                                                                           ## target 
                                                                                                                                                                                           ## tag 
                                                                                                                                                                                           ## for 
                                                                                                                                                                                           ## a 
                                                                                                                                                                                           ## policy.</p> 
                                                                                                                                                                                           ## <p>Tags 
                                                                                                                                                                                           ## are 
                                                                                                                                                                                           ## strings 
                                                                                                                                                                                           ## in 
                                                                                                                                                                                           ## the 
                                                                                                                                                                                           ## format 
                                                                                                                                                                                           ## <code>key=value</code>.</p>
  ##   
                                                                                                                                                                                                                         ## policyIds: JArray
                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                         ## identifiers 
                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                         ## data 
                                                                                                                                                                                                                         ## lifecycle 
                                                                                                                                                                                                                         ## policies.
  ##   
                                                                                                                                                                                                                                     ## tagsToAdd: JArray
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## <p>The 
                                                                                                                                                                                                                                     ## tags 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## add 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## objects 
                                                                                                                                                                                                                                     ## created 
                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## policy.</p> 
                                                                                                                                                                                                                                     ## <p>Tags 
                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                     ## strings 
                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## format 
                                                                                                                                                                                                                                     ## <code>key=value</code>.</p> 
                                                                                                                                                                                                                                     ## <p>These 
                                                                                                                                                                                                                                     ## user-defined 
                                                                                                                                                                                                                                     ## tags 
                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                     ## added 
                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                     ## addition 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## AWS-added 
                                                                                                                                                                                                                                     ## lifecycle 
                                                                                                                                                                                                                                     ## tags.</p>
  var query_402656456 = newJObject()
  add(query_402656456, "state", newJString(state))
  if resourceTypes != nil:
    query_402656456.add "resourceTypes", resourceTypes
  if targetTags != nil:
    query_402656456.add "targetTags", targetTags
  if policyIds != nil:
    query_402656456.add "policyIds", policyIds
  if tagsToAdd != nil:
    query_402656456.add "tagsToAdd", tagsToAdd
  result = call_402656455.call(nil, query_402656456, nil, nil, nil)

var getLifecyclePolicies* = Call_GetLifecyclePolicies_402656288(
    name: "getLifecyclePolicies", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_GetLifecyclePolicies_402656289, base: "/",
    makeUrl: url_GetLifecyclePolicies_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_402656500 = ref object of OpenApiRestCall_402656038
proc url_GetLifecyclePolicy_402656502(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLifecyclePolicy_402656501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets detailed information about the specified lifecycle policy.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
                                 ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `policyId` field"
  var valid_402656514 = path.getOrDefault("policyId")
  valid_402656514 = validateParameter(valid_402656514, JString, required = true,
                                      default = nil)
  if valid_402656514 != nil:
    section.add "policyId", valid_402656514
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

proc call*(call_402656522: Call_GetLifecyclePolicy_402656500;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets detailed information about the specified lifecycle policy.
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

proc call*(call_402656523: Call_GetLifecyclePolicy_402656500; policyId: string): Recallable =
  ## getLifecyclePolicy
  ## Gets detailed information about the specified lifecycle policy.
  ##   policyId: string (required)
                                                                    ##           : The identifier of the lifecycle policy.
  var path_402656524 = newJObject()
  add(path_402656524, "policyId", newJString(policyId))
  result = call_402656523.call(path_402656524, nil, nil, nil, nil)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_402656500(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_GetLifecyclePolicy_402656501, base: "/",
    makeUrl: url_GetLifecyclePolicy_402656502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_402656525 = ref object of OpenApiRestCall_402656038
proc url_DeleteLifecyclePolicy_402656527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLifecyclePolicy_402656526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
                                 ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `policyId` field"
  var valid_402656528 = path.getOrDefault("policyId")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true,
                                      default = nil)
  if valid_402656528 != nil:
    section.add "policyId", valid_402656528
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

proc call*(call_402656536: Call_DeleteLifecyclePolicy_402656525;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
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

proc call*(call_402656537: Call_DeleteLifecyclePolicy_402656525;
           policyId: string): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ##   
                                                                                                         ## policyId: string (required)
                                                                                                         ##           
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## identifier 
                                                                                                         ## of 
                                                                                                         ## the 
                                                                                                         ## lifecycle 
                                                                                                         ## policy.
  var path_402656538 = newJObject()
  add(path_402656538, "policyId", newJString(policyId))
  result = call_402656537.call(path_402656538, nil, nil, nil, nil)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_402656525(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpDelete,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_DeleteLifecyclePolicy_402656526, base: "/",
    makeUrl: url_DeleteLifecyclePolicy_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656553 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656555(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656554(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656556 = path.getOrDefault("resourceArn")
  valid_402656556 = validateParameter(valid_402656556, JString, required = true,
                                      default = nil)
  if valid_402656556 != nil:
    section.add "resourceArn", valid_402656556
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
  var valid_402656557 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Security-Token", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Signature")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Signature", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Algorithm", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Date")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Date", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Credential")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Credential", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656563
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

proc call*(call_402656565: Call_TagResource_402656553; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tags to the specified resource.
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_TagResource_402656553; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402656567 = newJObject()
  var body_402656568 = newJObject()
  if body != nil:
    body_402656568 = body
  add(path_402656567, "resourceArn", newJString(resourceArn))
  result = call_402656566.call(path_402656567, nil, nil, nil, body_402656568)

var tagResource* = Call_TagResource_402656553(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "dlm.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656554,
    base: "/", makeUrl: url_TagResource_402656555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656539 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656541(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656542 = path.getOrDefault("resourceArn")
  valid_402656542 = validateParameter(valid_402656542, JString, required = true,
                                      default = nil)
  if valid_402656542 != nil:
    section.add "resourceArn", valid_402656542
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
  if body != nil:
    result.add "body", body

proc call*(call_402656550: Call_ListTagsForResource_402656539;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
                                                                                         ## 
  let valid = call_402656550.validator(path, query, header, formData, body, _)
  let scheme = call_402656550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656550.makeUrl(scheme.get, call_402656550.host, call_402656550.base,
                                   call_402656550.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656550, uri, valid, _)

proc call*(call_402656551: Call_ListTagsForResource_402656539;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
                                               ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402656552 = newJObject()
  add(path_402656552, "resourceArn", newJString(resourceArn))
  result = call_402656551.call(path_402656552, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656539(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656540, base: "/",
    makeUrl: url_ListTagsForResource_402656541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656569 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656571(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656570(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656572 = path.getOrDefault("resourceArn")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "resourceArn", valid_402656572
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656573 = query.getOrDefault("tagKeys")
  valid_402656573 = validateParameter(valid_402656573, JArray, required = true,
                                      default = nil)
  if valid_402656573 != nil:
    section.add "tagKeys", valid_402656573
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
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656581: Call_UntagResource_402656569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource.
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

proc call*(call_402656582: Call_UntagResource_402656569; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   tagKeys: JArray (required)
                                                            ##          : The tag keys.
  ##   
                                                                                       ## resourceArn: string (required)
                                                                                       ##              
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## Amazon 
                                                                                       ## Resource 
                                                                                       ## Name 
                                                                                       ## (ARN) 
                                                                                       ## of 
                                                                                       ## the 
                                                                                       ## resource.
  var path_402656583 = newJObject()
  var query_402656584 = newJObject()
  if tagKeys != nil:
    query_402656584.add "tagKeys", tagKeys
  add(path_402656583, "resourceArn", newJString(resourceArn))
  result = call_402656582.call(path_402656583, query_402656584, nil, nil, nil)

var untagResource* = Call_UntagResource_402656569(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dlm.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656570,
    base: "/", makeUrl: url_UntagResource_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLifecyclePolicy_402656585 = ref object of OpenApiRestCall_402656038
proc url_UpdateLifecyclePolicy_402656587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLifecyclePolicy_402656586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified lifecycle policy.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
                                 ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `policyId` field"
  var valid_402656588 = path.getOrDefault("policyId")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true,
                                      default = nil)
  if valid_402656588 != nil:
    section.add "policyId", valid_402656588
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

proc call*(call_402656597: Call_UpdateLifecyclePolicy_402656585;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified lifecycle policy.
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

proc call*(call_402656598: Call_UpdateLifecyclePolicy_402656585; body: JsonNode;
           policyId: string): Recallable =
  ## updateLifecyclePolicy
  ## Updates the specified lifecycle policy.
  ##   body: JObject (required)
  ##   policyId: string (required)
                               ##           : The identifier of the lifecycle policy.
  var path_402656599 = newJObject()
  var body_402656600 = newJObject()
  if body != nil:
    body_402656600 = body
  add(path_402656599, "policyId", newJString(policyId))
  result = call_402656598.call(path_402656599, nil, nil, nil, body_402656600)

var updateLifecyclePolicy* = Call_UpdateLifecyclePolicy_402656585(
    name: "updateLifecyclePolicy", meth: HttpMethod.HttpPatch,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}",
    validator: validate_UpdateLifecyclePolicy_402656586, base: "/",
    makeUrl: url_UpdateLifecyclePolicy_402656587,
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