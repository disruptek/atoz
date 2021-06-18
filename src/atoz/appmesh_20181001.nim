
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2018-10-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control containerized microservices. App Mesh standardizes how your microservices
##          communicate, giving you end-to-end visibility and helping to ensure high-availability for
##          your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with Amazon ECS
##          (using the Amazon EC2 launch type), Amazon EKS, and Kubernetes on AWS.</p>
##          <note>
##             <p>App Mesh supports containerized microservice applications that use service discovery
##             naming for their components. To use App Mesh, you must have a containerized application
##             running on Amazon EC2 instances, hosted in either Amazon ECS, Amazon EKS, or Kubernetes on AWS. For
##             more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> is supported.
##             For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
##                for Services and Pods</a> in the Kubernetes documentation.</p>
##          </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appmesh/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
                               "us-west-2": "appmesh.us-west-2.amazonaws.com",
                               "eu-west-2": "appmesh.eu-west-2.amazonaws.com", "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com", "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
                               "us-east-2": "appmesh.us-east-2.amazonaws.com",
                               "us-east-1": "appmesh.us-east-1.amazonaws.com", "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "appmesh.ap-south-1.amazonaws.com", "eu-north-1": "appmesh.eu-north-1.amazonaws.com", "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
                               "us-west-1": "appmesh.us-west-1.amazonaws.com", "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "appmesh.eu-west-3.amazonaws.com", "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
                               "eu-west-1": "appmesh.eu-west-1.amazonaws.com", "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com", "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
      "us-west-2": "appmesh.us-west-2.amazonaws.com",
      "eu-west-2": "appmesh.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
      "us-east-2": "appmesh.us-east-2.amazonaws.com",
      "us-east-1": "appmesh.us-east-1.amazonaws.com",
      "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
      "eu-north-1": "appmesh.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
      "us-west-1": "appmesh.us-west-1.amazonaws.com",
      "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
      "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
      "eu-west-1": "appmesh.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appmesh"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateMesh_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateMesh_402656479(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMesh_402656478(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
                ##          between the services that reside within it.</p>
                ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
                ##          routes to distribute traffic between the applications in your mesh.</p>
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
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
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

proc call*(call_402656488: Call_CreateMesh_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
                                                                                         ##          between the services that reside within it.</p>
                                                                                         ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
                                                                                         ##          routes to distribute traffic between the applications in your mesh.</p>
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateMesh_402656477; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
               ##          between the services that reside within it.</p>
               ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
               ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   
                                                                                                  ## body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createMesh* = Call_CreateMesh_402656477(name: "createMesh",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com", route: "/meshes",
    validator: validate_CreateMesh_402656478, base: "/",
    makeUrl: url_CreateMesh_402656479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListMeshes_402656296(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeshes_402656295(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing service meshes.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
                                  ##          
                                  ## <code>ListMeshes</code> request where <code>limit</code> was used and the
                                  ##          
                                  ## results exceeded the value of that parameter. Pagination continues from the end of the
                                  ##          
                                  ## previous results that returned the <code>nextToken</code> value.</p>
                                  ##          
                                  ## <note>
                                  ##             <p>This token should be treated as an opaque identifier that is only used to
                                  ##                 
                                  ## retrieve the next items in a list and not for other programmatic purposes.</p>
                                  ##         
                                  ## </note>
  ##   limit: JInt
                                            ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
                                            ##          
                                            ## output. When this parameter is used, <code>ListMeshes</code> only returns
                                            ##             
                                            ## <code>limit</code> results in a single page along with a 
                                            ## <code>nextToken</code> 
                                            ## response
                                            ##          element. The remaining results of the initial request can be seen by sending another
                                            ##             
                                            ## <code>ListMeshes</code> request with the returned 
                                            ## <code>nextToken</code> 
                                            ## value. This
                                            ##          value can be between 1 and 100. If this parameter is not
                                            ##          
                                            ## used, then <code>ListMeshes</code> returns up to 100 results and a
                                            ##             
                                            ## <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_402656375 = query.getOrDefault("nextToken")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "nextToken", valid_402656375
  var valid_402656376 = query.getOrDefault("limit")
  valid_402656376 = validateParameter(valid_402656376, JInt, required = false,
                                      default = nil)
  if valid_402656376 != nil:
    section.add "limit", valid_402656376
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
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListMeshes_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing service meshes.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListMeshes_402656294; nextToken: string = "";
           limit: int = 0): Recallable =
  ## listMeshes
  ## Returns a list of existing service meshes.
  ##   nextToken: string
                                               ##            : <p>The <code>nextToken</code> value returned from a previous paginated
                                               ##          
                                               ## <code>ListMeshes</code> request where <code>limit</code> was used and the
                                               ##          
                                               ## results exceeded the value of that parameter. Pagination continues from the end of the
                                               ##          
                                               ## previous results that returned the 
                                               ## <code>nextToken</code> 
                                               ## value.</p>
                                               ##          <note>
                                               ##             <p>This token should be treated as an opaque identifier that is only used to
                                               ##                 
                                               ## retrieve the next items in a list and not for other programmatic purposes.</p>
                                               ##         
                                               ## </note>
  ##   limit: int
                                                         ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
                                                         ##          
                                                         ## output. When this parameter is used, 
                                                         ## <code>ListMeshes</code> 
                                                         ## only 
                                                         ## returns
                                                         ##             
                                                         ## <code>limit</code> results in a single page along with a 
                                                         ## <code>nextToken</code> 
                                                         ## response
                                                         ##          element. The remaining results of the initial request can be seen by sending another
                                                         ##             
                                                         ## <code>ListMeshes</code> request with the returned 
                                                         ## <code>nextToken</code> 
                                                         ## value. 
                                                         ## This
                                                         ##          value can be between 1 and 100. If this parameter is not
                                                         ##          
                                                         ## used, then 
                                                         ## <code>ListMeshes</code> returns up to 100 results and a
                                                         ##             
                                                         ## <code>nextToken</code> value if 
                                                         ## applicable.
  var query_402656447 = newJObject()
  add(query_402656447, "nextToken", newJString(nextToken))
  add(query_402656447, "limit", newJInt(limit))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listMeshes* = Call_ListMeshes_402656294(name: "listMeshes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes",
    validator: validate_ListMeshes_402656295, base: "/",
    makeUrl: url_ListMeshes_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_402656520 = ref object of OpenApiRestCall_402656044
proc url_CreateRoute_402656522(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouter/"),
                 (kind: VariableSegment, value: "virtualRouterName"),
                 (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_402656521(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new route that is associated with a virtual router.</p>
                ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
                ##          routing of requests. For example, if your virtual router service name is
                ##             <code>my-service.local</code>, and you want the route to match requests to
                ##             <code>my-service.local/metrics</code>, then your prefix should be
                ##          <code>/metrics</code>.</p>
                ##          <p>If your route matches a request, you can distribute traffic to one or more target
                ##          virtual nodes with relative weighting.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
                                 ##                    : The name of the virtual router in which to create the route.
  ##   
                                                                                                                     ## meshName: JString (required)
                                                                                                                     ##           
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## name 
                                                                                                                     ## of 
                                                                                                                     ## the 
                                                                                                                     ## service 
                                                                                                                     ## mesh 
                                                                                                                     ## in 
                                                                                                                     ## which 
                                                                                                                     ## to 
                                                                                                                     ## create 
                                                                                                                     ## the 
                                                                                                                     ## route.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `virtualRouterName` field"
  var valid_402656523 = path.getOrDefault("virtualRouterName")
  valid_402656523 = validateParameter(valid_402656523, JString, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "virtualRouterName", valid_402656523
  var valid_402656524 = path.getOrDefault("meshName")
  valid_402656524 = validateParameter(valid_402656524, JString, required = true,
                                      default = nil)
  if valid_402656524 != nil:
    section.add "meshName", valid_402656524
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
  var valid_402656525 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Security-Token", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Signature")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Signature", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Algorithm", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Date")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Date", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Credential")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Credential", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656531
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

proc call*(call_402656533: Call_CreateRoute_402656520; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new route that is associated with a virtual router.</p>
                                                                                         ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
                                                                                         ##          routing of requests. For example, if your virtual router service name is
                                                                                         ##             <code>my-service.local</code>, and you want the route to match requests to
                                                                                         ##             <code>my-service.local/metrics</code>, then your prefix should be
                                                                                         ##          <code>/metrics</code>.</p>
                                                                                         ##          <p>If your route matches a request, you can distribute traffic to one or more target
                                                                                         ##          virtual nodes with relative weighting.</p>
                                                                                         ## 
  let valid = call_402656533.validator(path, query, header, formData, body, _)
  let scheme = call_402656533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656533.makeUrl(scheme.get, call_402656533.host, call_402656533.base,
                                   call_402656533.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656533, uri, valid, _)

proc call*(call_402656534: Call_CreateRoute_402656520;
           virtualRouterName: string; body: JsonNode; meshName: string): Recallable =
  ## createRoute
  ## <p>Creates a new route that is associated with a virtual router.</p>
                ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
                ##          routing of requests. For example, if your virtual router service name is
                ##             <code>my-service.local</code>, and you want the route to match requests to
                ##             <code>my-service.local/metrics</code>, then your prefix should be
                ##          <code>/metrics</code>.</p>
                ##          <p>If your route matches a request, you can distribute traffic to one or more target
                ##          virtual nodes with relative weighting.</p>
  ##   
                                                                      ## virtualRouterName: string (required)
                                                                      ##                    
                                                                      ## : 
                                                                      ## The name of the 
                                                                      ## virtual 
                                                                      ## router 
                                                                      ## in 
                                                                      ## which to 
                                                                      ## create 
                                                                      ## the 
                                                                      ## route.
  ##   
                                                                               ## body: JObject (required)
  ##   
                                                                                                          ## meshName: string (required)
                                                                                                          ##           
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## name 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## service 
                                                                                                          ## mesh 
                                                                                                          ## in 
                                                                                                          ## which 
                                                                                                          ## to 
                                                                                                          ## create 
                                                                                                          ## the 
                                                                                                          ## route.
  var path_402656535 = newJObject()
  var body_402656536 = newJObject()
  add(path_402656535, "virtualRouterName", newJString(virtualRouterName))
  if body != nil:
    body_402656536 = body
  add(path_402656535, "meshName", newJString(meshName))
  result = call_402656534.call(path_402656535, nil, nil, nil, body_402656536)

var createRoute* = Call_CreateRoute_402656520(name: "createRoute",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
    validator: validate_CreateRoute_402656521, base: "/",
    makeUrl: url_CreateRoute_402656522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListRoutes_402656493(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouter/"),
                 (kind: VariableSegment, value: "virtualRouterName"),
                 (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoutes_402656492(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing routes in a service mesh.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
                                 ##                    : The name of the virtual router in which to list routes.
  ##   
                                                                                                                ## meshName: JString (required)
                                                                                                                ##           
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## name 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## service 
                                                                                                                ## mesh 
                                                                                                                ## in 
                                                                                                                ## which 
                                                                                                                ## to 
                                                                                                                ## list 
                                                                                                                ## routes.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `virtualRouterName` field"
  var valid_402656505 = path.getOrDefault("virtualRouterName")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "virtualRouterName", valid_402656505
  var valid_402656506 = path.getOrDefault("meshName")
  valid_402656506 = validateParameter(valid_402656506, JString, required = true,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "meshName", valid_402656506
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : The <code>nextToken</code> value returned from a previous paginated
                                  ##          
                                  ## <code>ListRoutes</code> request where <code>limit</code> was used and the
                                  ##          
                                  ## results exceeded the value of that parameter. Pagination continues from the end of the
                                  ##          
                                  ## previous results that returned the <code>nextToken</code> value.
  ##   
                                                                                                     ## limit: JInt
                                                                                                     ##        
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## maximum 
                                                                                                     ## number 
                                                                                                     ## of 
                                                                                                     ## mesh 
                                                                                                     ## results 
                                                                                                     ## returned 
                                                                                                     ## by 
                                                                                                     ## <code>ListRoutes</code> 
                                                                                                     ## in 
                                                                                                     ## paginated
                                                                                                     ##          
                                                                                                     ## output. 
                                                                                                     ## When 
                                                                                                     ## this 
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## used, 
                                                                                                     ## <code>ListRoutes</code> 
                                                                                                     ## only 
                                                                                                     ## returns
                                                                                                     ##             
                                                                                                     ## <code>limit</code> 
                                                                                                     ## results 
                                                                                                     ## in 
                                                                                                     ## a 
                                                                                                     ## single 
                                                                                                     ## page 
                                                                                                     ## along 
                                                                                                     ## with 
                                                                                                     ## a 
                                                                                                     ## <code>nextToken</code> 
                                                                                                     ## response
                                                                                                     ##          
                                                                                                     ## element. 
                                                                                                     ## The 
                                                                                                     ## remaining 
                                                                                                     ## results 
                                                                                                     ## of 
                                                                                                     ## the 
                                                                                                     ## initial 
                                                                                                     ## request 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## seen 
                                                                                                     ## by 
                                                                                                     ## sending 
                                                                                                     ## another
                                                                                                     ##             
                                                                                                     ## <code>ListRoutes</code> 
                                                                                                     ## request 
                                                                                                     ## with 
                                                                                                     ## the 
                                                                                                     ## returned 
                                                                                                     ## <code>nextToken</code> 
                                                                                                     ## value. 
                                                                                                     ## This
                                                                                                     ##          
                                                                                                     ## value 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## between 
                                                                                                     ## 1 
                                                                                                     ## and 
                                                                                                     ## 100. 
                                                                                                     ## If 
                                                                                                     ## this 
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## not
                                                                                                     ##          
                                                                                                     ## used, 
                                                                                                     ## then 
                                                                                                     ## <code>ListRoutes</code> 
                                                                                                     ## returns 
                                                                                                     ## up 
                                                                                                     ## to 
                                                                                                     ## 100 
                                                                                                     ## results 
                                                                                                     ## and 
                                                                                                     ## a
                                                                                                     ##             
                                                                                                     ## <code>nextToken</code> 
                                                                                                     ## value 
                                                                                                     ## if 
                                                                                                     ## applicable.
  section = newJObject()
  var valid_402656507 = query.getOrDefault("nextToken")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "nextToken", valid_402656507
  var valid_402656508 = query.getOrDefault("limit")
  valid_402656508 = validateParameter(valid_402656508, JInt, required = false,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "limit", valid_402656508
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
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_ListRoutes_402656491; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing routes in a service mesh.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_ListRoutes_402656491; virtualRouterName: string;
           meshName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   virtualRouterName: string (required)
                                                         ##                    : The name of the virtual router in which to list routes.
  ##   
                                                                                                                                        ## nextToken: string
                                                                                                                                        ##            
                                                                                                                                        ## : 
                                                                                                                                        ## The 
                                                                                                                                        ## <code>nextToken</code> 
                                                                                                                                        ## value 
                                                                                                                                        ## returned 
                                                                                                                                        ## from 
                                                                                                                                        ## a 
                                                                                                                                        ## previous 
                                                                                                                                        ## paginated
                                                                                                                                        ##          
                                                                                                                                        ## <code>ListRoutes</code> 
                                                                                                                                        ## request 
                                                                                                                                        ## where 
                                                                                                                                        ## <code>limit</code> 
                                                                                                                                        ## was 
                                                                                                                                        ## used 
                                                                                                                                        ## and 
                                                                                                                                        ## the
                                                                                                                                        ##          
                                                                                                                                        ## results 
                                                                                                                                        ## exceeded 
                                                                                                                                        ## the 
                                                                                                                                        ## value 
                                                                                                                                        ## of 
                                                                                                                                        ## that 
                                                                                                                                        ## parameter. 
                                                                                                                                        ## Pagination 
                                                                                                                                        ## continues 
                                                                                                                                        ## from 
                                                                                                                                        ## the 
                                                                                                                                        ## end 
                                                                                                                                        ## of 
                                                                                                                                        ## the
                                                                                                                                        ##          
                                                                                                                                        ## previous 
                                                                                                                                        ## results 
                                                                                                                                        ## that 
                                                                                                                                        ## returned 
                                                                                                                                        ## the 
                                                                                                                                        ## <code>nextToken</code> 
                                                                                                                                        ## value.
  ##   
                                                                                                                                                 ## limit: int
                                                                                                                                                 ##        
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## maximum 
                                                                                                                                                 ## number 
                                                                                                                                                 ## of 
                                                                                                                                                 ## mesh 
                                                                                                                                                 ## results 
                                                                                                                                                 ## returned 
                                                                                                                                                 ## by 
                                                                                                                                                 ## <code>ListRoutes</code> 
                                                                                                                                                 ## in 
                                                                                                                                                 ## paginated
                                                                                                                                                 ##          
                                                                                                                                                 ## output. 
                                                                                                                                                 ## When 
                                                                                                                                                 ## this 
                                                                                                                                                 ## parameter 
                                                                                                                                                 ## is 
                                                                                                                                                 ## used, 
                                                                                                                                                 ## <code>ListRoutes</code> 
                                                                                                                                                 ## only 
                                                                                                                                                 ## returns
                                                                                                                                                 ##             
                                                                                                                                                 ## <code>limit</code> 
                                                                                                                                                 ## results 
                                                                                                                                                 ## in 
                                                                                                                                                 ## a 
                                                                                                                                                 ## single 
                                                                                                                                                 ## page 
                                                                                                                                                 ## along 
                                                                                                                                                 ## with 
                                                                                                                                                 ## a 
                                                                                                                                                 ## <code>nextToken</code> 
                                                                                                                                                 ## response
                                                                                                                                                 ##          
                                                                                                                                                 ## element. 
                                                                                                                                                 ## The 
                                                                                                                                                 ## remaining 
                                                                                                                                                 ## results 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## initial 
                                                                                                                                                 ## request 
                                                                                                                                                 ## can 
                                                                                                                                                 ## be 
                                                                                                                                                 ## seen 
                                                                                                                                                 ## by 
                                                                                                                                                 ## sending 
                                                                                                                                                 ## another
                                                                                                                                                 ##             
                                                                                                                                                 ## <code>ListRoutes</code> 
                                                                                                                                                 ## request 
                                                                                                                                                 ## with 
                                                                                                                                                 ## the 
                                                                                                                                                 ## returned 
                                                                                                                                                 ## <code>nextToken</code> 
                                                                                                                                                 ## value. 
                                                                                                                                                 ## This
                                                                                                                                                 ##          
                                                                                                                                                 ## value 
                                                                                                                                                 ## can 
                                                                                                                                                 ## be 
                                                                                                                                                 ## between 
                                                                                                                                                 ## 1 
                                                                                                                                                 ## and 
                                                                                                                                                 ## 100. 
                                                                                                                                                 ## If 
                                                                                                                                                 ## this 
                                                                                                                                                 ## parameter 
                                                                                                                                                 ## is 
                                                                                                                                                 ## not
                                                                                                                                                 ##          
                                                                                                                                                 ## used, 
                                                                                                                                                 ## then 
                                                                                                                                                 ## <code>ListRoutes</code> 
                                                                                                                                                 ## returns 
                                                                                                                                                 ## up 
                                                                                                                                                 ## to 
                                                                                                                                                 ## 100 
                                                                                                                                                 ## results 
                                                                                                                                                 ## and 
                                                                                                                                                 ## a
                                                                                                                                                 ##             
                                                                                                                                                 ## <code>nextToken</code> 
                                                                                                                                                 ## value 
                                                                                                                                                 ## if 
                                                                                                                                                 ## applicable.
  ##   
                                                                                                                                                               ## meshName: string (required)
                                                                                                                                                               ##           
                                                                                                                                                               ## : 
                                                                                                                                                               ## The 
                                                                                                                                                               ## name 
                                                                                                                                                               ## of 
                                                                                                                                                               ## the 
                                                                                                                                                               ## service 
                                                                                                                                                               ## mesh 
                                                                                                                                                               ## in 
                                                                                                                                                               ## which 
                                                                                                                                                               ## to 
                                                                                                                                                               ## list 
                                                                                                                                                               ## routes.
  var path_402656518 = newJObject()
  var query_402656519 = newJObject()
  add(path_402656518, "virtualRouterName", newJString(virtualRouterName))
  add(query_402656519, "nextToken", newJString(nextToken))
  add(query_402656519, "limit", newJInt(limit))
  add(path_402656518, "meshName", newJString(meshName))
  result = call_402656517.call(path_402656518, query_402656519, nil, nil, nil)

var listRoutes* = Call_ListRoutes_402656491(name: "listRoutes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
    validator: validate_ListRoutes_402656492, base: "/",
    makeUrl: url_ListRoutes_402656493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_402656554 = ref object of OpenApiRestCall_402656044
proc url_CreateVirtualNode_402656556(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualNode_402656555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new virtual node within a service mesh.</p>
                ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
                ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
                ##          DNS service discovery name for your task group.</p>
                ##          <p>Any inbound traffic that your virtual node expects should be specified as a
                ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
                ##          should be specified as a <code>backend</code>.</p>
                ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
                ##          associated with the virtual node. Set this value (either the full ARN or the truncated
                ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
                ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
                ##          proxy container in your task definition or pod spec. This is then mapped to the
                ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
                ##          <note>
                ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
                ##             the <code>node.cluster</code> value that is set by
                ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
                ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
                ##          </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which to create the virtual node.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656557 = path.getOrDefault("meshName")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "meshName", valid_402656557
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
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
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

proc call*(call_402656566: Call_CreateVirtualNode_402656554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new virtual node within a service mesh.</p>
                                                                                         ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
                                                                                         ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
                                                                                         ##          DNS service discovery name for your task group.</p>
                                                                                         ##          <p>Any inbound traffic that your virtual node expects should be specified as a
                                                                                         ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
                                                                                         ##          should be specified as a <code>backend</code>.</p>
                                                                                         ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
                                                                                         ##          associated with the virtual node. Set this value (either the full ARN or the truncated
                                                                                         ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
                                                                                         ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
                                                                                         ##          proxy container in your task definition or pod spec. This is then mapped to the
                                                                                         ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
                                                                                         ##          <note>
                                                                                         ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
                                                                                         ##             the <code>node.cluster</code> value that is set by
                                                                                         ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
                                                                                         ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
                                                                                         ##          </note>
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

proc call*(call_402656567: Call_CreateVirtualNode_402656554; body: JsonNode;
           meshName: string): Recallable =
  ## createVirtualNode
  ## <p>Creates a new virtual node within a service mesh.</p>
                      ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
                      ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
                      ##          DNS service discovery name for your task group.</p>
                      ##          <p>Any inbound traffic that your virtual node expects should be specified as a
                      ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
                      ##          should be specified as a <code>backend</code>.</p>
                      ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
                      ##          associated with the virtual node. Set this value (either the full ARN or the truncated
                      ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
                      ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
                      ##          proxy container in your task definition or pod spec. This is then mapped to the
                      ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
                      ##          <note>
                      ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
                      ##             the <code>node.cluster</code> value that is set by
                      ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
                      ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
                      ##          </note>
  ##   body: JObject (required)
  ##   meshName: string (required)
                               ##           : The name of the service mesh in which to create the virtual node.
  var path_402656568 = newJObject()
  var body_402656569 = newJObject()
  if body != nil:
    body_402656569 = body
  add(path_402656568, "meshName", newJString(meshName))
  result = call_402656567.call(path_402656568, nil, nil, nil, body_402656569)

var createVirtualNode* = Call_CreateVirtualNode_402656554(
    name: "createVirtualNode", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_402656555, base: "/",
    makeUrl: url_CreateVirtualNode_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_402656537 = ref object of OpenApiRestCall_402656044
proc url_ListVirtualNodes_402656539(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualNodes_402656538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing virtual nodes.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which to list virtual nodes.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656540 = path.getOrDefault("meshName")
  valid_402656540 = validateParameter(valid_402656540, JString, required = true,
                                      default = nil)
  if valid_402656540 != nil:
    section.add "meshName", valid_402656540
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : The <code>nextToken</code> value returned from a previous paginated
                                  ##          
                                  ## <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
                                  ##          
                                  ## results exceeded the value of that parameter. Pagination continues from the end of the
                                  ##          
                                  ## previous results that returned the <code>nextToken</code> value.
  ##   
                                                                                                     ## limit: JInt
                                                                                                     ##        
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## maximum 
                                                                                                     ## number 
                                                                                                     ## of 
                                                                                                     ## mesh 
                                                                                                     ## results 
                                                                                                     ## returned 
                                                                                                     ## by 
                                                                                                     ## <code>ListVirtualNodes</code> 
                                                                                                     ## in
                                                                                                     ##          
                                                                                                     ## paginated 
                                                                                                     ## output. 
                                                                                                     ## When 
                                                                                                     ## this 
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## used, 
                                                                                                     ## <code>ListVirtualNodes</code> 
                                                                                                     ## only 
                                                                                                     ## returns
                                                                                                     ##          
                                                                                                     ## <code>limit</code> 
                                                                                                     ## results 
                                                                                                     ## in 
                                                                                                     ## a 
                                                                                                     ## single 
                                                                                                     ## page 
                                                                                                     ## along 
                                                                                                     ## with 
                                                                                                     ## a 
                                                                                                     ## <code>nextToken</code>
                                                                                                     ##          
                                                                                                     ## response 
                                                                                                     ## element. 
                                                                                                     ## The 
                                                                                                     ## remaining 
                                                                                                     ## results 
                                                                                                     ## of 
                                                                                                     ## the 
                                                                                                     ## initial 
                                                                                                     ## request 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## seen 
                                                                                                     ## by 
                                                                                                     ## sending
                                                                                                     ##          
                                                                                                     ## another 
                                                                                                     ## <code>ListVirtualNodes</code> 
                                                                                                     ## request 
                                                                                                     ## with 
                                                                                                     ## the 
                                                                                                     ## returned 
                                                                                                     ## <code>nextToken</code>
                                                                                                     ##          
                                                                                                     ## value. 
                                                                                                     ## This 
                                                                                                     ## value 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## between 
                                                                                                     ## 1 
                                                                                                     ## and 
                                                                                                     ## 100. 
                                                                                                     ## If 
                                                                                                     ## this
                                                                                                     ##          
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## not 
                                                                                                     ## used, 
                                                                                                     ## then 
                                                                                                     ## <code>ListVirtualNodes</code> 
                                                                                                     ## returns 
                                                                                                     ## up 
                                                                                                     ## to
                                                                                                     ##          
                                                                                                     ## 100 
                                                                                                     ## results 
                                                                                                     ## and 
                                                                                                     ## a 
                                                                                                     ## <code>nextToken</code> 
                                                                                                     ## value 
                                                                                                     ## if 
                                                                                                     ## applicable.
  section = newJObject()
  var valid_402656541 = query.getOrDefault("nextToken")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "nextToken", valid_402656541
  var valid_402656542 = query.getOrDefault("limit")
  valid_402656542 = validateParameter(valid_402656542, JInt, required = false,
                                      default = nil)
  if valid_402656542 != nil:
    section.add "limit", valid_402656542
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

proc call*(call_402656550: Call_ListVirtualNodes_402656537;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing virtual nodes.
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

proc call*(call_402656551: Call_ListVirtualNodes_402656537; meshName: string;
           nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   nextToken: string
                                              ##            : The <code>nextToken</code> value returned from a previous paginated
                                              ##          
                                              ## <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
                                              ##          
                                              ## results exceeded the value of that parameter. Pagination continues from the end of the
                                              ##          
                                              ## previous results that returned the <code>nextToken</code> value.
  ##   
                                                                                                                 ## limit: int
                                                                                                                 ##        
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## maximum 
                                                                                                                 ## number 
                                                                                                                 ## of 
                                                                                                                 ## mesh 
                                                                                                                 ## results 
                                                                                                                 ## returned 
                                                                                                                 ## by 
                                                                                                                 ## <code>ListVirtualNodes</code> 
                                                                                                                 ## in
                                                                                                                 ##          
                                                                                                                 ## paginated 
                                                                                                                 ## output. 
                                                                                                                 ## When 
                                                                                                                 ## this 
                                                                                                                 ## parameter 
                                                                                                                 ## is 
                                                                                                                 ## used, 
                                                                                                                 ## <code>ListVirtualNodes</code> 
                                                                                                                 ## only 
                                                                                                                 ## returns
                                                                                                                 ##          
                                                                                                                 ## <code>limit</code> 
                                                                                                                 ## results 
                                                                                                                 ## in 
                                                                                                                 ## a 
                                                                                                                 ## single 
                                                                                                                 ## page 
                                                                                                                 ## along 
                                                                                                                 ## with 
                                                                                                                 ## a 
                                                                                                                 ## <code>nextToken</code>
                                                                                                                 ##          
                                                                                                                 ## response 
                                                                                                                 ## element. 
                                                                                                                 ## The 
                                                                                                                 ## remaining 
                                                                                                                 ## results 
                                                                                                                 ## of 
                                                                                                                 ## the 
                                                                                                                 ## initial 
                                                                                                                 ## request 
                                                                                                                 ## can 
                                                                                                                 ## be 
                                                                                                                 ## seen 
                                                                                                                 ## by 
                                                                                                                 ## sending
                                                                                                                 ##          
                                                                                                                 ## another 
                                                                                                                 ## <code>ListVirtualNodes</code> 
                                                                                                                 ## request 
                                                                                                                 ## with 
                                                                                                                 ## the 
                                                                                                                 ## returned 
                                                                                                                 ## <code>nextToken</code>
                                                                                                                 ##          
                                                                                                                 ## value. 
                                                                                                                 ## This 
                                                                                                                 ## value 
                                                                                                                 ## can 
                                                                                                                 ## be 
                                                                                                                 ## between 
                                                                                                                 ## 1 
                                                                                                                 ## and 
                                                                                                                 ## 100. 
                                                                                                                 ## If 
                                                                                                                 ## this
                                                                                                                 ##          
                                                                                                                 ## parameter 
                                                                                                                 ## is 
                                                                                                                 ## not 
                                                                                                                 ## used, 
                                                                                                                 ## then 
                                                                                                                 ## <code>ListVirtualNodes</code> 
                                                                                                                 ## returns 
                                                                                                                 ## up 
                                                                                                                 ## to
                                                                                                                 ##          
                                                                                                                 ## 100 
                                                                                                                 ## results 
                                                                                                                 ## and 
                                                                                                                 ## a 
                                                                                                                 ## <code>nextToken</code> 
                                                                                                                 ## value 
                                                                                                                 ## if 
                                                                                                                 ## applicable.
  ##   
                                                                                                                               ## meshName: string (required)
                                                                                                                               ##           
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## name 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## service 
                                                                                                                               ## mesh 
                                                                                                                               ## in 
                                                                                                                               ## which 
                                                                                                                               ## to 
                                                                                                                               ## list 
                                                                                                                               ## virtual 
                                                                                                                               ## nodes.
  var path_402656552 = newJObject()
  var query_402656553 = newJObject()
  add(query_402656553, "nextToken", newJString(nextToken))
  add(query_402656553, "limit", newJInt(limit))
  add(path_402656552, "meshName", newJString(meshName))
  result = call_402656551.call(path_402656552, query_402656553, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_402656537(
    name: "listVirtualNodes", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_402656538, base: "/",
    makeUrl: url_ListVirtualNodes_402656539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_402656587 = ref object of OpenApiRestCall_402656044
proc url_CreateVirtualRouter_402656589(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualRouter_402656588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new virtual router within a service mesh.</p>
                ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
                ##          create your virtual router, create and associate routes for your virtual router that direct
                ##          incoming requests to different virtual nodes.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which to create the virtual router.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656590 = path.getOrDefault("meshName")
  valid_402656590 = validateParameter(valid_402656590, JString, required = true,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "meshName", valid_402656590
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
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
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

proc call*(call_402656599: Call_CreateVirtualRouter_402656587;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new virtual router within a service mesh.</p>
                                                                                         ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
                                                                                         ##          create your virtual router, create and associate routes for your virtual router that direct
                                                                                         ##          incoming requests to different virtual nodes.</p>
                                                                                         ## 
  let valid = call_402656599.validator(path, query, header, formData, body, _)
  let scheme = call_402656599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656599.makeUrl(scheme.get, call_402656599.host, call_402656599.base,
                                   call_402656599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656599, uri, valid, _)

proc call*(call_402656600: Call_CreateVirtualRouter_402656587; body: JsonNode;
           meshName: string): Recallable =
  ## createVirtualRouter
  ## <p>Creates a new virtual router within a service mesh.</p>
                        ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
                        ##          create your virtual router, create and associate routes for your virtual router that direct
                        ##          incoming requests to different virtual nodes.</p>
  ##   
                                                                                     ## body: JObject (required)
  ##   
                                                                                                                ## meshName: string (required)
                                                                                                                ##           
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## name 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## service 
                                                                                                                ## mesh 
                                                                                                                ## in 
                                                                                                                ## which 
                                                                                                                ## to 
                                                                                                                ## create 
                                                                                                                ## the 
                                                                                                                ## virtual 
                                                                                                                ## router.
  var path_402656601 = newJObject()
  var body_402656602 = newJObject()
  if body != nil:
    body_402656602 = body
  add(path_402656601, "meshName", newJString(meshName))
  result = call_402656600.call(path_402656601, nil, nil, nil, body_402656602)

var createVirtualRouter* = Call_CreateVirtualRouter_402656587(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_402656588, base: "/",
    makeUrl: url_CreateVirtualRouter_402656589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_402656570 = ref object of OpenApiRestCall_402656044
proc url_ListVirtualRouters_402656572(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualRouters_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing virtual routers in a service mesh.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which to list virtual routers.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656573 = path.getOrDefault("meshName")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true,
                                      default = nil)
  if valid_402656573 != nil:
    section.add "meshName", valid_402656573
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
                                  ##            : The <code>nextToken</code> value returned from a previous paginated
                                  ##          
                                  ## <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
                                  ##          
                                  ## results exceeded the value of that parameter. Pagination continues from the end of the
                                  ##          
                                  ## previous results that returned the <code>nextToken</code> value.
  ##   
                                                                                                     ## limit: JInt
                                                                                                     ##        
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## maximum 
                                                                                                     ## number 
                                                                                                     ## of 
                                                                                                     ## mesh 
                                                                                                     ## results 
                                                                                                     ## returned 
                                                                                                     ## by 
                                                                                                     ## <code>ListVirtualRouters</code> 
                                                                                                     ## in
                                                                                                     ##          
                                                                                                     ## paginated 
                                                                                                     ## output. 
                                                                                                     ## When 
                                                                                                     ## this 
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## used, 
                                                                                                     ## <code>ListVirtualRouters</code> 
                                                                                                     ## only 
                                                                                                     ## returns
                                                                                                     ##          
                                                                                                     ## <code>limit</code> 
                                                                                                     ## results 
                                                                                                     ## in 
                                                                                                     ## a 
                                                                                                     ## single 
                                                                                                     ## page 
                                                                                                     ## along 
                                                                                                     ## with 
                                                                                                     ## a 
                                                                                                     ## <code>nextToken</code>
                                                                                                     ##          
                                                                                                     ## response 
                                                                                                     ## element. 
                                                                                                     ## The 
                                                                                                     ## remaining 
                                                                                                     ## results 
                                                                                                     ## of 
                                                                                                     ## the 
                                                                                                     ## initial 
                                                                                                     ## request 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## seen 
                                                                                                     ## by 
                                                                                                     ## sending
                                                                                                     ##          
                                                                                                     ## another 
                                                                                                     ## <code>ListVirtualRouters</code> 
                                                                                                     ## request 
                                                                                                     ## with 
                                                                                                     ## the 
                                                                                                     ## returned 
                                                                                                     ## <code>nextToken</code>
                                                                                                     ##          
                                                                                                     ## value. 
                                                                                                     ## This 
                                                                                                     ## value 
                                                                                                     ## can 
                                                                                                     ## be 
                                                                                                     ## between 
                                                                                                     ## 1 
                                                                                                     ## and 
                                                                                                     ## 100. 
                                                                                                     ## If 
                                                                                                     ## this
                                                                                                     ##          
                                                                                                     ## parameter 
                                                                                                     ## is 
                                                                                                     ## not 
                                                                                                     ## used, 
                                                                                                     ## then 
                                                                                                     ## <code>ListVirtualRouters</code> 
                                                                                                     ## returns 
                                                                                                     ## up 
                                                                                                     ## to
                                                                                                     ##          
                                                                                                     ## 100 
                                                                                                     ## results 
                                                                                                     ## and 
                                                                                                     ## a 
                                                                                                     ## <code>nextToken</code> 
                                                                                                     ## value 
                                                                                                     ## if 
                                                                                                     ## applicable.
  section = newJObject()
  var valid_402656574 = query.getOrDefault("nextToken")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "nextToken", valid_402656574
  var valid_402656575 = query.getOrDefault("limit")
  valid_402656575 = validateParameter(valid_402656575, JInt, required = false,
                                      default = nil)
  if valid_402656575 != nil:
    section.add "limit", valid_402656575
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
  var valid_402656576 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Security-Token", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Signature")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Signature", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Algorithm", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Date")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Date", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Credential")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Credential", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656583: Call_ListVirtualRouters_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
                                                                                         ## 
  let valid = call_402656583.validator(path, query, header, formData, body, _)
  let scheme = call_402656583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656583.makeUrl(scheme.get, call_402656583.host, call_402656583.base,
                                   call_402656583.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656583, uri, valid, _)

proc call*(call_402656584: Call_ListVirtualRouters_402656570; meshName: string;
           nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   nextToken: string
                                                                  ##            : The <code>nextToken</code> value returned from a previous paginated
                                                                  ##          
                                                                  ## <code>ListVirtualRouters</code> 
                                                                  ## request 
                                                                  ## where 
                                                                  ## <code>limit</code> was used and the
                                                                  ##          
                                                                  ## results 
                                                                  ## exceeded the 
                                                                  ## value 
                                                                  ## of that 
                                                                  ## parameter. 
                                                                  ## Pagination 
                                                                  ## continues 
                                                                  ## from 
                                                                  ## the end of the
                                                                  ##          
                                                                  ## previous 
                                                                  ## results 
                                                                  ## that 
                                                                  ## returned the 
                                                                  ## <code>nextToken</code> 
                                                                  ## value.
  ##   
                                                                           ## limit: int
                                                                           ##        
                                                                           ## : 
                                                                           ## The 
                                                                           ## maximum 
                                                                           ## number 
                                                                           ## of 
                                                                           ## mesh 
                                                                           ## results 
                                                                           ## returned 
                                                                           ## by 
                                                                           ## <code>ListVirtualRouters</code> 
                                                                           ## in
                                                                           ##          
                                                                           ## paginated 
                                                                           ## output. 
                                                                           ## When 
                                                                           ## this 
                                                                           ## parameter 
                                                                           ## is 
                                                                           ## used, 
                                                                           ## <code>ListVirtualRouters</code> 
                                                                           ## only 
                                                                           ## returns
                                                                           ##          
                                                                           ## <code>limit</code> 
                                                                           ## results 
                                                                           ## in 
                                                                           ## a 
                                                                           ## single 
                                                                           ## page 
                                                                           ## along 
                                                                           ## with 
                                                                           ## a 
                                                                           ## <code>nextToken</code>
                                                                           ##          
                                                                           ## response 
                                                                           ## element. 
                                                                           ## The 
                                                                           ## remaining 
                                                                           ## results 
                                                                           ## of 
                                                                           ## the 
                                                                           ## initial 
                                                                           ## request 
                                                                           ## can 
                                                                           ## be 
                                                                           ## seen 
                                                                           ## by 
                                                                           ## sending
                                                                           ##          
                                                                           ## another 
                                                                           ## <code>ListVirtualRouters</code> 
                                                                           ## request 
                                                                           ## with 
                                                                           ## the 
                                                                           ## returned 
                                                                           ## <code>nextToken</code>
                                                                           ##          
                                                                           ## value. 
                                                                           ## This 
                                                                           ## value 
                                                                           ## can 
                                                                           ## be 
                                                                           ## between 
                                                                           ## 1 
                                                                           ## and 
                                                                           ## 100. 
                                                                           ## If 
                                                                           ## this
                                                                           ##          
                                                                           ## parameter 
                                                                           ## is 
                                                                           ## not 
                                                                           ## used, 
                                                                           ## then 
                                                                           ## <code>ListVirtualRouters</code> 
                                                                           ## returns 
                                                                           ## up 
                                                                           ## to
                                                                           ##          
                                                                           ## 100 
                                                                           ## results 
                                                                           ## and 
                                                                           ## a 
                                                                           ## <code>nextToken</code> 
                                                                           ## value 
                                                                           ## if 
                                                                           ## applicable.
  ##   
                                                                                         ## meshName: string (required)
                                                                                         ##           
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## name 
                                                                                         ## of 
                                                                                         ## the 
                                                                                         ## service 
                                                                                         ## mesh 
                                                                                         ## in 
                                                                                         ## which 
                                                                                         ## to 
                                                                                         ## list 
                                                                                         ## virtual 
                                                                                         ## routers.
  var path_402656585 = newJObject()
  var query_402656586 = newJObject()
  add(query_402656586, "nextToken", newJString(nextToken))
  add(query_402656586, "limit", newJInt(limit))
  add(path_402656585, "meshName", newJString(meshName))
  result = call_402656584.call(path_402656585, query_402656586, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_402656570(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_402656571, base: "/",
    makeUrl: url_ListVirtualRouters_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_402656603 = ref object of OpenApiRestCall_402656044
proc url_DescribeMesh_402656605(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMesh_402656604(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing service mesh.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656606 = path.getOrDefault("meshName")
  valid_402656606 = validateParameter(valid_402656606, JString, required = true,
                                      default = nil)
  if valid_402656606 != nil:
    section.add "meshName", valid_402656606
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
  var valid_402656607 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Security-Token", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Signature")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Signature", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Algorithm", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Date")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Date", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Credential")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Credential", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656614: Call_DescribeMesh_402656603; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing service mesh.
                                                                                         ## 
  let valid = call_402656614.validator(path, query, header, formData, body, _)
  let scheme = call_402656614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656614.makeUrl(scheme.get, call_402656614.host, call_402656614.base,
                                   call_402656614.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656614, uri, valid, _)

proc call*(call_402656615: Call_DescribeMesh_402656603; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
                                        ##           : The name of the service mesh to describe.
  var path_402656616 = newJObject()
  add(path_402656616, "meshName", newJString(meshName))
  result = call_402656615.call(path_402656616, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_402656603(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_402656604,
    base: "/", makeUrl: url_DescribeMesh_402656605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_402656617 = ref object of OpenApiRestCall_402656044
proc url_DeleteMesh_402656619(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMesh_402656618(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an existing service mesh.</p>
                ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
                ##          mesh before you can delete the mesh itself.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656620 = path.getOrDefault("meshName")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = nil)
  if valid_402656620 != nil:
    section.add "meshName", valid_402656620
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
  var valid_402656621 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Security-Token", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Signature")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Signature", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Algorithm", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Date")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Date", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Credential")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Credential", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656628: Call_DeleteMesh_402656617; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing service mesh.</p>
                                                                                         ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
                                                                                         ##          mesh before you can delete the mesh itself.</p>
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_DeleteMesh_402656617; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
               ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
               ##          mesh before you can delete the mesh itself.</p>
  ##   
                                                                          ## meshName: string (required)
                                                                          ##           
                                                                          ## : 
                                                                          ## The 
                                                                          ## name 
                                                                          ## of 
                                                                          ## the 
                                                                          ## service 
                                                                          ## mesh 
                                                                          ## to 
                                                                          ## delete.
  var path_402656630 = newJObject()
  add(path_402656630, "meshName", newJString(meshName))
  result = call_402656629.call(path_402656630, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_402656617(name: "deleteMesh",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DeleteMesh_402656618,
    base: "/", makeUrl: url_DeleteMesh_402656619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_402656647 = ref object of OpenApiRestCall_402656044
proc url_UpdateRoute_402656649(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouter/"),
                 (kind: VariableSegment, value: "virtualRouterName"),
                 (kind: ConstantSegment, value: "/routes/"),
                 (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_402656648(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing route for a specified service mesh and virtual router.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
                                 ##            : The name of the route to update.
  ##   
                                                                                 ## virtualRouterName: JString (required)
                                                                                 ##                    
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## name 
                                                                                 ## of 
                                                                                 ## the 
                                                                                 ## virtual 
                                                                                 ## router 
                                                                                 ## with 
                                                                                 ## which 
                                                                                 ## the 
                                                                                 ## route 
                                                                                 ## is 
                                                                                 ## associated.
  ##   
                                                                                               ## meshName: JString (required)
                                                                                               ##           
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## name 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## service 
                                                                                               ## mesh 
                                                                                               ## in 
                                                                                               ## which 
                                                                                               ## the 
                                                                                               ## route 
                                                                                               ## resides.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeName` field"
  var valid_402656650 = path.getOrDefault("routeName")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "routeName", valid_402656650
  var valid_402656651 = path.getOrDefault("virtualRouterName")
  valid_402656651 = validateParameter(valid_402656651, JString, required = true,
                                      default = nil)
  if valid_402656651 != nil:
    section.add "virtualRouterName", valid_402656651
  var valid_402656652 = path.getOrDefault("meshName")
  valid_402656652 = validateParameter(valid_402656652, JString, required = true,
                                      default = nil)
  if valid_402656652 != nil:
    section.add "meshName", valid_402656652
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
  var valid_402656653 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Security-Token", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Signature")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Signature", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Algorithm", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Date")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Date", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Credential")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Credential", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656659
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

proc call*(call_402656661: Call_UpdateRoute_402656647; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_UpdateRoute_402656647; routeName: string;
           virtualRouterName: string; body: JsonNode; meshName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   
                                                                               ## routeName: string (required)
                                                                               ##            
                                                                               ## : 
                                                                               ## The 
                                                                               ## name 
                                                                               ## of 
                                                                               ## the 
                                                                               ## route 
                                                                               ## to 
                                                                               ## update.
  ##   
                                                                                         ## virtualRouterName: string (required)
                                                                                         ##                    
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## name 
                                                                                         ## of 
                                                                                         ## the 
                                                                                         ## virtual 
                                                                                         ## router 
                                                                                         ## with 
                                                                                         ## which 
                                                                                         ## the 
                                                                                         ## route 
                                                                                         ## is 
                                                                                         ## associated.
  ##   
                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                  ## meshName: string (required)
                                                                                                                                  ##           
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## name 
                                                                                                                                  ## of 
                                                                                                                                  ## the 
                                                                                                                                  ## service 
                                                                                                                                  ## mesh 
                                                                                                                                  ## in 
                                                                                                                                  ## which 
                                                                                                                                  ## the 
                                                                                                                                  ## route 
                                                                                                                                  ## resides.
  var path_402656663 = newJObject()
  var body_402656664 = newJObject()
  add(path_402656663, "routeName", newJString(routeName))
  add(path_402656663, "virtualRouterName", newJString(virtualRouterName))
  if body != nil:
    body_402656664 = body
  add(path_402656663, "meshName", newJString(meshName))
  result = call_402656662.call(path_402656663, nil, nil, nil, body_402656664)

var updateRoute* = Call_UpdateRoute_402656647(name: "updateRoute",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_UpdateRoute_402656648, base: "/",
    makeUrl: url_UpdateRoute_402656649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_402656631 = ref object of OpenApiRestCall_402656044
proc url_DescribeRoute_402656633(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouter/"),
                 (kind: VariableSegment, value: "virtualRouterName"),
                 (kind: ConstantSegment, value: "/routes/"),
                 (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRoute_402656632(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
                                 ##            : The name of the route to describe.
  ##   
                                                                                   ## virtualRouterName: JString (required)
                                                                                   ##                    
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## name 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## virtual 
                                                                                   ## router 
                                                                                   ## with 
                                                                                   ## which 
                                                                                   ## the 
                                                                                   ## route 
                                                                                   ## is 
                                                                                   ## associated.
  ##   
                                                                                                 ## meshName: JString (required)
                                                                                                 ##           
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## name 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## service 
                                                                                                 ## mesh 
                                                                                                 ## in 
                                                                                                 ## which 
                                                                                                 ## the 
                                                                                                 ## route 
                                                                                                 ## resides.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeName` field"
  var valid_402656634 = path.getOrDefault("routeName")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "routeName", valid_402656634
  var valid_402656635 = path.getOrDefault("virtualRouterName")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "virtualRouterName", valid_402656635
  var valid_402656636 = path.getOrDefault("meshName")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = nil)
  if valid_402656636 != nil:
    section.add "meshName", valid_402656636
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
  var valid_402656637 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Security-Token", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Signature")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Signature", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Algorithm", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Date")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Date", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Credential")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Credential", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656644: Call_DescribeRoute_402656631; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing route.
                                                                                         ## 
  let valid = call_402656644.validator(path, query, header, formData, body, _)
  let scheme = call_402656644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656644.makeUrl(scheme.get, call_402656644.host, call_402656644.base,
                                   call_402656644.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656644, uri, valid, _)

proc call*(call_402656645: Call_DescribeRoute_402656631; routeName: string;
           virtualRouterName: string; meshName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
                                 ##            : The name of the route to describe.
  ##   
                                                                                   ## virtualRouterName: string (required)
                                                                                   ##                    
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## name 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## virtual 
                                                                                   ## router 
                                                                                   ## with 
                                                                                   ## which 
                                                                                   ## the 
                                                                                   ## route 
                                                                                   ## is 
                                                                                   ## associated.
  ##   
                                                                                                 ## meshName: string (required)
                                                                                                 ##           
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## name 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## service 
                                                                                                 ## mesh 
                                                                                                 ## in 
                                                                                                 ## which 
                                                                                                 ## the 
                                                                                                 ## route 
                                                                                                 ## resides.
  var path_402656646 = newJObject()
  add(path_402656646, "routeName", newJString(routeName))
  add(path_402656646, "virtualRouterName", newJString(virtualRouterName))
  add(path_402656646, "meshName", newJString(meshName))
  result = call_402656645.call(path_402656646, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_402656631(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_402656632, base: "/",
    makeUrl: url_DescribeRoute_402656633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_402656665 = ref object of OpenApiRestCall_402656044
proc url_DeleteRoute_402656667(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouter/"),
                 (kind: VariableSegment, value: "virtualRouterName"),
                 (kind: ConstantSegment, value: "/routes/"),
                 (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_402656666(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
                                 ##            : The name of the route to delete.
  ##   
                                                                                 ## virtualRouterName: JString (required)
                                                                                 ##                    
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## name 
                                                                                 ## of 
                                                                                 ## the 
                                                                                 ## virtual 
                                                                                 ## router 
                                                                                 ## in 
                                                                                 ## which 
                                                                                 ## to 
                                                                                 ## delete 
                                                                                 ## the 
                                                                                 ## route.
  ##   
                                                                                          ## meshName: JString (required)
                                                                                          ##           
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## name 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## service 
                                                                                          ## mesh 
                                                                                          ## in 
                                                                                          ## which 
                                                                                          ## to 
                                                                                          ## delete 
                                                                                          ## the 
                                                                                          ## route.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeName` field"
  var valid_402656668 = path.getOrDefault("routeName")
  valid_402656668 = validateParameter(valid_402656668, JString, required = true,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "routeName", valid_402656668
  var valid_402656669 = path.getOrDefault("virtualRouterName")
  valid_402656669 = validateParameter(valid_402656669, JString, required = true,
                                      default = nil)
  if valid_402656669 != nil:
    section.add "virtualRouterName", valid_402656669
  var valid_402656670 = path.getOrDefault("meshName")
  valid_402656670 = validateParameter(valid_402656670, JString, required = true,
                                      default = nil)
  if valid_402656670 != nil:
    section.add "meshName", valid_402656670
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
  var valid_402656671 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Security-Token", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Signature")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Signature", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Algorithm", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Date")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Date", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Credential")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Credential", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656678: Call_DeleteRoute_402656665; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing route.
                                                                                         ## 
  let valid = call_402656678.validator(path, query, header, formData, body, _)
  let scheme = call_402656678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656678.makeUrl(scheme.get, call_402656678.host, call_402656678.base,
                                   call_402656678.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656678, uri, valid, _)

proc call*(call_402656679: Call_DeleteRoute_402656665; routeName: string;
           virtualRouterName: string; meshName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
                               ##            : The name of the route to delete.
  ##   
                                                                               ## virtualRouterName: string (required)
                                                                               ##                    
                                                                               ## : 
                                                                               ## The 
                                                                               ## name 
                                                                               ## of 
                                                                               ## the 
                                                                               ## virtual 
                                                                               ## router 
                                                                               ## in 
                                                                               ## which 
                                                                               ## to 
                                                                               ## delete 
                                                                               ## the 
                                                                               ## route.
  ##   
                                                                                        ## meshName: string (required)
                                                                                        ##           
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## name 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## service 
                                                                                        ## mesh 
                                                                                        ## in 
                                                                                        ## which 
                                                                                        ## to 
                                                                                        ## delete 
                                                                                        ## the 
                                                                                        ## route.
  var path_402656680 = newJObject()
  add(path_402656680, "routeName", newJString(routeName))
  add(path_402656680, "virtualRouterName", newJString(virtualRouterName))
  add(path_402656680, "meshName", newJString(meshName))
  result = call_402656679.call(path_402656680, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_402656665(name: "deleteRoute",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DeleteRoute_402656666, base: "/",
    makeUrl: url_DeleteRoute_402656667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_402656696 = ref object of OpenApiRestCall_402656044
proc url_UpdateVirtualNode_402656698(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path,
         "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualNodes/"),
                 (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualNode_402656697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing virtual node in a specified service mesh.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which the virtual node resides.
  ##   
                                                                                                               ## virtualNodeName: JString (required)
                                                                                                               ##                  
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## name 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## virtual 
                                                                                                               ## node 
                                                                                                               ## to 
                                                                                                               ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656699 = path.getOrDefault("meshName")
  valid_402656699 = validateParameter(valid_402656699, JString, required = true,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "meshName", valid_402656699
  var valid_402656700 = path.getOrDefault("virtualNodeName")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "virtualNodeName", valid_402656700
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
  var valid_402656701 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Security-Token", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Signature")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Signature", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Algorithm", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Date")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Date", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Credential")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Credential", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
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

proc call*(call_402656709: Call_UpdateVirtualNode_402656696;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_UpdateVirtualNode_402656696; body: JsonNode;
           meshName: string; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   body: JObject (required)
  ##   meshName: string (required)
                               ##           : The name of the service mesh in which the virtual node resides.
  ##   
                                                                                                             ## virtualNodeName: string (required)
                                                                                                             ##                  
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## name 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## virtual 
                                                                                                             ## node 
                                                                                                             ## to 
                                                                                                             ## update.
  var path_402656711 = newJObject()
  var body_402656712 = newJObject()
  if body != nil:
    body_402656712 = body
  add(path_402656711, "meshName", newJString(meshName))
  add(path_402656711, "virtualNodeName", newJString(virtualNodeName))
  result = call_402656710.call(path_402656711, nil, nil, nil, body_402656712)

var updateVirtualNode* = Call_UpdateVirtualNode_402656696(
    name: "updateVirtualNode", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_402656697, base: "/",
    makeUrl: url_UpdateVirtualNode_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_402656681 = ref object of OpenApiRestCall_402656044
proc url_DescribeVirtualNode_402656683(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path,
         "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualNodes/"),
                 (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualNode_402656682(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing virtual node.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which the virtual node resides.
  ##   
                                                                                                               ## virtualNodeName: JString (required)
                                                                                                               ##                  
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## name 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## virtual 
                                                                                                               ## node 
                                                                                                               ## to 
                                                                                                               ## describe.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656684 = path.getOrDefault("meshName")
  valid_402656684 = validateParameter(valid_402656684, JString, required = true,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "meshName", valid_402656684
  var valid_402656685 = path.getOrDefault("virtualNodeName")
  valid_402656685 = validateParameter(valid_402656685, JString, required = true,
                                      default = nil)
  if valid_402656685 != nil:
    section.add "virtualNodeName", valid_402656685
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
  var valid_402656686 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Security-Token", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Signature")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Signature", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Algorithm", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Date")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Date", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Credential")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Credential", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656693: Call_DescribeVirtualNode_402656681;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing virtual node.
                                                                                         ## 
  let valid = call_402656693.validator(path, query, header, formData, body, _)
  let scheme = call_402656693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656693.makeUrl(scheme.get, call_402656693.host, call_402656693.base,
                                   call_402656693.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656693, uri, valid, _)

proc call*(call_402656694: Call_DescribeVirtualNode_402656681; meshName: string;
           virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
                                        ##           : The name of the service mesh in which the virtual node resides.
  ##   
                                                                                                                      ## virtualNodeName: string (required)
                                                                                                                      ##                  
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## name 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## virtual 
                                                                                                                      ## node 
                                                                                                                      ## to 
                                                                                                                      ## describe.
  var path_402656695 = newJObject()
  add(path_402656695, "meshName", newJString(meshName))
  add(path_402656695, "virtualNodeName", newJString(virtualNodeName))
  result = call_402656694.call(path_402656695, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_402656681(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_402656682, base: "/",
    makeUrl: url_DescribeVirtualNode_402656683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_402656713 = ref object of OpenApiRestCall_402656044
proc url_DeleteVirtualNode_402656715(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path,
         "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualNodes/"),
                 (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualNode_402656714(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing virtual node.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
                                 ##           : The name of the service mesh in which to delete the virtual node.
  ##   
                                                                                                                 ## virtualNodeName: JString (required)
                                                                                                                 ##                  
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## name 
                                                                                                                 ## of 
                                                                                                                 ## the 
                                                                                                                 ## virtual 
                                                                                                                 ## node 
                                                                                                                 ## to 
                                                                                                                 ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `meshName` field"
  var valid_402656716 = path.getOrDefault("meshName")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "meshName", valid_402656716
  var valid_402656717 = path.getOrDefault("virtualNodeName")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "virtualNodeName", valid_402656717
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
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656725: Call_DeleteVirtualNode_402656713;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing virtual node.
                                                                                         ## 
  let valid = call_402656725.validator(path, query, header, formData, body, _)
  let scheme = call_402656725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656725.makeUrl(scheme.get, call_402656725.host, call_402656725.base,
                                   call_402656725.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656725, uri, valid, _)

proc call*(call_402656726: Call_DeleteVirtualNode_402656713; meshName: string;
           virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
                                      ##           : The name of the service mesh in which to delete the virtual node.
  ##   
                                                                                                                      ## virtualNodeName: string (required)
                                                                                                                      ##                  
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## name 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## virtual 
                                                                                                                      ## node 
                                                                                                                      ## to 
                                                                                                                      ## delete.
  var path_402656727 = newJObject()
  add(path_402656727, "meshName", newJString(meshName))
  add(path_402656727, "virtualNodeName", newJString(virtualNodeName))
  result = call_402656726.call(path_402656727, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_402656713(
    name: "deleteVirtualNode", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_402656714, base: "/",
    makeUrl: url_DeleteVirtualNode_402656715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_402656743 = ref object of OpenApiRestCall_402656044
proc url_UpdateVirtualRouter_402656745(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouters/"),
                 (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_402656744(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing virtual router in a specified service mesh.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
                                 ##                    : The name of the virtual router to update.
  ##   
                                                                                                  ## meshName: JString (required)
                                                                                                  ##           
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## name 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## service 
                                                                                                  ## mesh 
                                                                                                  ## in 
                                                                                                  ## which 
                                                                                                  ## the 
                                                                                                  ## virtual 
                                                                                                  ## router 
                                                                                                  ## resides.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `virtualRouterName` field"
  var valid_402656746 = path.getOrDefault("virtualRouterName")
  valid_402656746 = validateParameter(valid_402656746, JString, required = true,
                                      default = nil)
  if valid_402656746 != nil:
    section.add "virtualRouterName", valid_402656746
  var valid_402656747 = path.getOrDefault("meshName")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true,
                                      default = nil)
  if valid_402656747 != nil:
    section.add "meshName", valid_402656747
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
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_UpdateVirtualRouter_402656743;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_UpdateVirtualRouter_402656743;
           virtualRouterName: string; body: JsonNode; meshName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   
                                                                    ## virtualRouterName: string (required)
                                                                    ##                    
                                                                    ## : 
                                                                    ## The name of the virtual router to update.
  ##   
                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                           ## meshName: string (required)
                                                                                                                                           ##           
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## name 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## service 
                                                                                                                                           ## mesh 
                                                                                                                                           ## in 
                                                                                                                                           ## which 
                                                                                                                                           ## the 
                                                                                                                                           ## virtual 
                                                                                                                                           ## router 
                                                                                                                                           ## resides.
  var path_402656758 = newJObject()
  var body_402656759 = newJObject()
  add(path_402656758, "virtualRouterName", newJString(virtualRouterName))
  if body != nil:
    body_402656759 = body
  add(path_402656758, "meshName", newJString(meshName))
  result = call_402656757.call(path_402656758, nil, nil, nil, body_402656759)

var updateVirtualRouter* = Call_UpdateVirtualRouter_402656743(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_402656744, base: "/",
    makeUrl: url_UpdateVirtualRouter_402656745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_402656728 = ref object of OpenApiRestCall_402656044
proc url_DescribeVirtualRouter_402656730(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouters/"),
                 (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_402656729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing virtual router.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
                                 ##                    : The name of the virtual router to describe.
  ##   
                                                                                                    ## meshName: JString (required)
                                                                                                    ##           
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## name 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## service 
                                                                                                    ## mesh 
                                                                                                    ## in 
                                                                                                    ## which 
                                                                                                    ## the 
                                                                                                    ## virtual 
                                                                                                    ## router 
                                                                                                    ## resides.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `virtualRouterName` field"
  var valid_402656731 = path.getOrDefault("virtualRouterName")
  valid_402656731 = validateParameter(valid_402656731, JString, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "virtualRouterName", valid_402656731
  var valid_402656732 = path.getOrDefault("meshName")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "meshName", valid_402656732
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
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656740: Call_DescribeVirtualRouter_402656728;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing virtual router.
                                                                                         ## 
  let valid = call_402656740.validator(path, query, header, formData, body, _)
  let scheme = call_402656740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656740.makeUrl(scheme.get, call_402656740.host, call_402656740.base,
                                   call_402656740.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656740, uri, valid, _)

proc call*(call_402656741: Call_DescribeVirtualRouter_402656728;
           virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
                                          ##                    : The name of the virtual router to describe.
  ##   
                                                                                                             ## meshName: string (required)
                                                                                                             ##           
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## name 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## service 
                                                                                                             ## mesh 
                                                                                                             ## in 
                                                                                                             ## which 
                                                                                                             ## the 
                                                                                                             ## virtual 
                                                                                                             ## router 
                                                                                                             ## resides.
  var path_402656742 = newJObject()
  add(path_402656742, "virtualRouterName", newJString(virtualRouterName))
  add(path_402656742, "meshName", newJString(meshName))
  result = call_402656741.call(path_402656742, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_402656728(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_402656729, base: "/",
    makeUrl: url_DescribeVirtualRouter_402656730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_402656760 = ref object of OpenApiRestCall_402656044
proc url_DeleteVirtualRouter_402656762(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
         "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
                 (kind: VariableSegment, value: "meshName"),
                 (kind: ConstantSegment, value: "/virtualRouters/"),
                 (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_402656761(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an existing virtual router.</p>
                ##          <p>You must delete any routes associated with the virtual router before you can delete the
                ##          router itself.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
                                 ##                    : The name of the virtual router to delete.
  ##   
                                                                                                  ## meshName: JString (required)
                                                                                                  ##           
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## name 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## service 
                                                                                                  ## mesh 
                                                                                                  ## in 
                                                                                                  ## which 
                                                                                                  ## to 
                                                                                                  ## delete 
                                                                                                  ## the 
                                                                                                  ## virtual 
                                                                                                  ## router.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `virtualRouterName` field"
  var valid_402656763 = path.getOrDefault("virtualRouterName")
  valid_402656763 = validateParameter(valid_402656763, JString, required = true,
                                      default = nil)
  if valid_402656763 != nil:
    section.add "virtualRouterName", valid_402656763
  var valid_402656764 = path.getOrDefault("meshName")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true,
                                      default = nil)
  if valid_402656764 != nil:
    section.add "meshName", valid_402656764
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
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656772: Call_DeleteVirtualRouter_402656760;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing virtual router.</p>
                                                                                         ##          <p>You must delete any routes associated with the virtual router before you can delete the
                                                                                         ##          router itself.</p>
                                                                                         ## 
  let valid = call_402656772.validator(path, query, header, formData, body, _)
  let scheme = call_402656772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656772.makeUrl(scheme.get, call_402656772.host, call_402656772.base,
                                   call_402656772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656772, uri, valid, _)

proc call*(call_402656773: Call_DeleteVirtualRouter_402656760;
           virtualRouterName: string; meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
                        ##          <p>You must delete any routes associated with the virtual router before you can delete the
                        ##          router itself.</p>
  ##   virtualRouterName: string (required)
                                                      ##                    : The name of the virtual router to delete.
  ##   
                                                                                                                       ## meshName: string (required)
                                                                                                                       ##           
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## name 
                                                                                                                       ## of 
                                                                                                                       ## the 
                                                                                                                       ## service 
                                                                                                                       ## mesh 
                                                                                                                       ## in 
                                                                                                                       ## which 
                                                                                                                       ## to 
                                                                                                                       ## delete 
                                                                                                                       ## the 
                                                                                                                       ## virtual 
                                                                                                                       ## router.
  var path_402656774 = newJObject()
  add(path_402656774, "virtualRouterName", newJString(virtualRouterName))
  add(path_402656774, "meshName", newJString(meshName))
  result = call_402656773.call(path_402656774, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_402656760(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_402656761, base: "/",
    makeUrl: url_DeleteVirtualRouter_402656762,
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