
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appmesh.us-west-2.amazonaws.com",
                           "eu-west-2": "appmesh.eu-west-2.amazonaws.com", "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com", "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
                           "us-east-2": "appmesh.us-east-2.amazonaws.com",
                           "us-east-1": "appmesh.us-east-1.amazonaws.com", "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
                           "eu-north-1": "appmesh.eu-north-1.amazonaws.com", "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appmesh.us-west-1.amazonaws.com", "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
                           "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
                           "eu-west-1": "appmesh.eu-west-1.amazonaws.com", "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_611253 = ref object of OpenApiRestCall_610658
proc url_CreateMesh_611255(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMesh_611254(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611256 = header.getOrDefault("X-Amz-Signature")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Signature", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Content-Sha256", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Date")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Date", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Credential")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Credential", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Security-Token")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Security-Token", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Algorithm")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Algorithm", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-SignedHeaders", valid_611262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611264: Call_CreateMesh_611253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ## 
  let valid = call_611264.validator(path, query, header, formData, body)
  let scheme = call_611264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611264.url(scheme.get, call_611264.host, call_611264.base,
                         call_611264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611264, url, valid)

proc call*(call_611265: Call_CreateMesh_611253; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   body: JObject (required)
  var body_611266 = newJObject()
  if body != nil:
    body_611266 = body
  result = call_611265.call(nil, nil, nil, nil, body_611266)

var createMesh* = Call_CreateMesh_611253(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_CreateMesh_611254,
                                      base: "/", url: url_CreateMesh_611255,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_610996 = ref object of OpenApiRestCall_610658
proc url_ListMeshes_610998(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeshes_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing service meshes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("limit")
  valid_611111 = validateParameter(valid_611111, JInt, required = false, default = nil)
  if valid_611111 != nil:
    section.add "limit", valid_611111
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
  var valid_611112 = header.getOrDefault("X-Amz-Signature")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Signature", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Content-Sha256", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Date")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Date", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Credential")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Credential", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Security-Token")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Security-Token", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Algorithm")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Algorithm", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-SignedHeaders", valid_611118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611141: Call_ListMeshes_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_611141.validator(path, query, header, formData, body)
  let scheme = call_611141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611141.url(scheme.get, call_611141.host, call_611141.base,
                         call_611141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611141, url, valid)

proc call*(call_611212: Call_ListMeshes_610996; nextToken: string = ""; limit: int = 0): Recallable =
  ## listMeshes
  ## Returns a list of existing service meshes.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_611213 = newJObject()
  add(query_611213, "nextToken", newJString(nextToken))
  add(query_611213, "limit", newJInt(limit))
  result = call_611212.call(nil, query_611213, nil, nil, nil)

var listMeshes* = Call_ListMeshes_610996(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_ListMeshes_610997,
                                      base: "/", url: url_ListMeshes_610998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_611299 = ref object of OpenApiRestCall_610658
proc url_CreateRoute_611301(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_611300(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the route.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611302 = path.getOrDefault("meshName")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "meshName", valid_611302
  var valid_611303 = path.getOrDefault("virtualRouterName")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = nil)
  if valid_611303 != nil:
    section.add "virtualRouterName", valid_611303
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
  var valid_611304 = header.getOrDefault("X-Amz-Signature")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Signature", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Content-Sha256", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Date")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Date", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Credential")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Credential", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Security-Token")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Security-Token", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Algorithm")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Algorithm", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-SignedHeaders", valid_611310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611312: Call_CreateRoute_611299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  let valid = call_611312.validator(path, query, header, formData, body)
  let scheme = call_611312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611312.url(scheme.get, call_611312.host, call_611312.base,
                         call_611312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611312, url, valid)

proc call*(call_611313: Call_CreateRoute_611299; meshName: string; body: JsonNode;
          virtualRouterName: string): Recallable =
  ## createRoute
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the route.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  var path_611314 = newJObject()
  var body_611315 = newJObject()
  add(path_611314, "meshName", newJString(meshName))
  if body != nil:
    body_611315 = body
  add(path_611314, "virtualRouterName", newJString(virtualRouterName))
  result = call_611313.call(path_611314, nil, nil, nil, body_611315)

var createRoute* = Call_CreateRoute_611299(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_611300,
                                        base: "/", url: url_CreateRoute_611301,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_611267 = ref object of OpenApiRestCall_610658
proc url_ListRoutes_611269(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRoutes_611268(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list routes.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to list routes.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611284 = path.getOrDefault("meshName")
  valid_611284 = validateParameter(valid_611284, JString, required = true,
                                 default = nil)
  if valid_611284 != nil:
    section.add "meshName", valid_611284
  var valid_611285 = path.getOrDefault("virtualRouterName")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "virtualRouterName", valid_611285
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_611286 = query.getOrDefault("nextToken")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "nextToken", valid_611286
  var valid_611287 = query.getOrDefault("limit")
  valid_611287 = validateParameter(valid_611287, JInt, required = false, default = nil)
  if valid_611287 != nil:
    section.add "limit", valid_611287
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
  var valid_611288 = header.getOrDefault("X-Amz-Signature")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Signature", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Content-Sha256", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Date")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Date", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Credential")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Credential", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Security-Token")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Security-Token", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Algorithm")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Algorithm", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-SignedHeaders", valid_611294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611295: Call_ListRoutes_611267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_611295.validator(path, query, header, formData, body)
  let scheme = call_611295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611295.url(scheme.get, call_611295.host, call_611295.base,
                         call_611295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611295, url, valid)

proc call*(call_611296: Call_ListRoutes_611267; meshName: string;
          virtualRouterName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list routes.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to list routes.
  var path_611297 = newJObject()
  var query_611298 = newJObject()
  add(query_611298, "nextToken", newJString(nextToken))
  add(query_611298, "limit", newJInt(limit))
  add(path_611297, "meshName", newJString(meshName))
  add(path_611297, "virtualRouterName", newJString(virtualRouterName))
  result = call_611296.call(path_611297, query_611298, nil, nil, nil)

var listRoutes* = Call_ListRoutes_611267(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_611268,
                                      base: "/", url: url_ListRoutes_611269,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_611333 = ref object of OpenApiRestCall_610658
proc url_CreateVirtualNode_611335(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateVirtualNode_611334(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611336 = path.getOrDefault("meshName")
  valid_611336 = validateParameter(valid_611336, JString, required = true,
                                 default = nil)
  if valid_611336 != nil:
    section.add "meshName", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_CreateVirtualNode_611333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
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
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_CreateVirtualNode_611333; meshName: string;
          body: JsonNode): Recallable =
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
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual node.
  ##   body: JObject (required)
  var path_611347 = newJObject()
  var body_611348 = newJObject()
  add(path_611347, "meshName", newJString(meshName))
  if body != nil:
    body_611348 = body
  result = call_611346.call(path_611347, nil, nil, nil, body_611348)

var createVirtualNode* = Call_CreateVirtualNode_611333(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_611334, base: "/",
    url: url_CreateVirtualNode_611335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_611316 = ref object of OpenApiRestCall_610658
proc url_ListVirtualNodes_611318(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListVirtualNodes_611317(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of existing virtual nodes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611319 = path.getOrDefault("meshName")
  valid_611319 = validateParameter(valid_611319, JString, required = true,
                                 default = nil)
  if valid_611319 != nil:
    section.add "meshName", valid_611319
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_611320 = query.getOrDefault("nextToken")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "nextToken", valid_611320
  var valid_611321 = query.getOrDefault("limit")
  valid_611321 = validateParameter(valid_611321, JInt, required = false, default = nil)
  if valid_611321 != nil:
    section.add "limit", valid_611321
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
  var valid_611322 = header.getOrDefault("X-Amz-Signature")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Signature", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Content-Sha256", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Date")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Date", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Credential")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Credential", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Security-Token")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Security-Token", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Algorithm")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Algorithm", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-SignedHeaders", valid_611328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611329: Call_ListVirtualNodes_611316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_611329.validator(path, query, header, formData, body)
  let scheme = call_611329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611329.url(scheme.get, call_611329.host, call_611329.base,
                         call_611329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611329, url, valid)

proc call*(call_611330: Call_ListVirtualNodes_611316; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  var path_611331 = newJObject()
  var query_611332 = newJObject()
  add(query_611332, "nextToken", newJString(nextToken))
  add(query_611332, "limit", newJInt(limit))
  add(path_611331, "meshName", newJString(meshName))
  result = call_611330.call(path_611331, query_611332, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_611316(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_611317, base: "/",
    url: url_ListVirtualNodes_611318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_611366 = ref object of OpenApiRestCall_610658
proc url_CreateVirtualRouter_611368(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateVirtualRouter_611367(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611369 = path.getOrDefault("meshName")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = nil)
  if valid_611369 != nil:
    section.add "meshName", valid_611369
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
  var valid_611370 = header.getOrDefault("X-Amz-Signature")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Signature", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Content-Sha256", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611378: Call_CreateVirtualRouter_611366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_611378.validator(path, query, header, formData, body)
  let scheme = call_611378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611378.url(scheme.get, call_611378.host, call_611378.base,
                         call_611378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611378, url, valid)

proc call*(call_611379: Call_CreateVirtualRouter_611366; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual router.
  ##   body: JObject (required)
  var path_611380 = newJObject()
  var body_611381 = newJObject()
  add(path_611380, "meshName", newJString(meshName))
  if body != nil:
    body_611381 = body
  result = call_611379.call(path_611380, nil, nil, nil, body_611381)

var createVirtualRouter* = Call_CreateVirtualRouter_611366(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_611367, base: "/",
    url: url_CreateVirtualRouter_611368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_611349 = ref object of OpenApiRestCall_610658
proc url_ListVirtualRouters_611351(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListVirtualRouters_611350(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list virtual routers.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611352 = path.getOrDefault("meshName")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "meshName", valid_611352
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_611353 = query.getOrDefault("nextToken")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "nextToken", valid_611353
  var valid_611354 = query.getOrDefault("limit")
  valid_611354 = validateParameter(valid_611354, JInt, required = false, default = nil)
  if valid_611354 != nil:
    section.add "limit", valid_611354
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
  var valid_611355 = header.getOrDefault("X-Amz-Signature")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Signature", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Content-Sha256", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Date")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Date", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Credential")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Credential", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Security-Token")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Security-Token", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Algorithm")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Algorithm", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-SignedHeaders", valid_611361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611362: Call_ListVirtualRouters_611349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_611362.validator(path, query, header, formData, body)
  let scheme = call_611362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611362.url(scheme.get, call_611362.host, call_611362.base,
                         call_611362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611362, url, valid)

proc call*(call_611363: Call_ListVirtualRouters_611349; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual routers.
  var path_611364 = newJObject()
  var query_611365 = newJObject()
  add(query_611365, "nextToken", newJString(nextToken))
  add(query_611365, "limit", newJInt(limit))
  add(path_611364, "meshName", newJString(meshName))
  result = call_611363.call(path_611364, query_611365, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_611349(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_611350, base: "/",
    url: url_ListVirtualRouters_611351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_611382 = ref object of OpenApiRestCall_610658
proc url_DescribeMesh_611384(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMesh_611383(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611385 = path.getOrDefault("meshName")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = nil)
  if valid_611385 != nil:
    section.add "meshName", valid_611385
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
  var valid_611386 = header.getOrDefault("X-Amz-Signature")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Signature", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Content-Sha256", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Date")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Date", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Credential")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Credential", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Security-Token")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Security-Token", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Algorithm")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Algorithm", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-SignedHeaders", valid_611392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611393: Call_DescribeMesh_611382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_611393.validator(path, query, header, formData, body)
  let scheme = call_611393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611393.url(scheme.get, call_611393.host, call_611393.base,
                         call_611393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611393, url, valid)

proc call*(call_611394: Call_DescribeMesh_611382; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_611395 = newJObject()
  add(path_611395, "meshName", newJString(meshName))
  result = call_611394.call(path_611395, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_611382(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_611383, base: "/",
    url: url_DescribeMesh_611384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_611396 = ref object of OpenApiRestCall_610658
proc url_DeleteMesh_611398(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteMesh_611397(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611399 = path.getOrDefault("meshName")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "meshName", valid_611399
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
  var valid_611400 = header.getOrDefault("X-Amz-Signature")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Signature", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Content-Sha256", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Date")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Date", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Credential")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Credential", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Security-Token")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Security-Token", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Algorithm")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Algorithm", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-SignedHeaders", valid_611406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611407: Call_DeleteMesh_611396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_611407.validator(path, query, header, formData, body)
  let scheme = call_611407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611407.url(scheme.get, call_611407.host, call_611407.base,
                         call_611407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611407, url, valid)

proc call*(call_611408: Call_DeleteMesh_611396; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_611409 = newJObject()
  add(path_611409, "meshName", newJString(meshName))
  result = call_611408.call(path_611409, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_611396(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes/{meshName}",
                                      validator: validate_DeleteMesh_611397,
                                      base: "/", url: url_DeleteMesh_611398,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_611426 = ref object of OpenApiRestCall_610658
proc url_UpdateRoute_611428(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_611427(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_611429 = path.getOrDefault("routeName")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "routeName", valid_611429
  var valid_611430 = path.getOrDefault("meshName")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "meshName", valid_611430
  var valid_611431 = path.getOrDefault("virtualRouterName")
  valid_611431 = validateParameter(valid_611431, JString, required = true,
                                 default = nil)
  if valid_611431 != nil:
    section.add "virtualRouterName", valid_611431
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
  var valid_611432 = header.getOrDefault("X-Amz-Signature")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Signature", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Content-Sha256", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Date")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Date", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Credential")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Credential", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Security-Token")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Security-Token", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Algorithm")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Algorithm", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-SignedHeaders", valid_611438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611440: Call_UpdateRoute_611426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_611440.validator(path, query, header, formData, body)
  let scheme = call_611440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611440.url(scheme.get, call_611440.host, call_611440.base,
                         call_611440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611440, url, valid)

proc call*(call_611441: Call_UpdateRoute_611426; routeName: string; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  var path_611442 = newJObject()
  var body_611443 = newJObject()
  add(path_611442, "routeName", newJString(routeName))
  add(path_611442, "meshName", newJString(meshName))
  if body != nil:
    body_611443 = body
  add(path_611442, "virtualRouterName", newJString(virtualRouterName))
  result = call_611441.call(path_611442, nil, nil, nil, body_611443)

var updateRoute* = Call_UpdateRoute_611426(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_611427,
                                        base: "/", url: url_UpdateRoute_611428,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_611410 = ref object of OpenApiRestCall_610658
proc url_DescribeRoute_611412(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRoute_611411(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_611413 = path.getOrDefault("routeName")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "routeName", valid_611413
  var valid_611414 = path.getOrDefault("meshName")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "meshName", valid_611414
  var valid_611415 = path.getOrDefault("virtualRouterName")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "virtualRouterName", valid_611415
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
  var valid_611416 = header.getOrDefault("X-Amz-Signature")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Signature", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Content-Sha256", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Date")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Date", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Credential")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Credential", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Security-Token")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Security-Token", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Algorithm")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Algorithm", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-SignedHeaders", valid_611422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611423: Call_DescribeRoute_611410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_611423.validator(path, query, header, formData, body)
  let scheme = call_611423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611423.url(scheme.get, call_611423.host, call_611423.base,
                         call_611423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611423, url, valid)

proc call*(call_611424: Call_DescribeRoute_611410; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  var path_611425 = newJObject()
  add(path_611425, "routeName", newJString(routeName))
  add(path_611425, "meshName", newJString(meshName))
  add(path_611425, "virtualRouterName", newJString(virtualRouterName))
  result = call_611424.call(path_611425, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_611410(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_611411, base: "/", url: url_DescribeRoute_611412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_611444 = ref object of OpenApiRestCall_610658
proc url_DeleteRoute_611446(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_611445(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to delete the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_611447 = path.getOrDefault("routeName")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = nil)
  if valid_611447 != nil:
    section.add "routeName", valid_611447
  var valid_611448 = path.getOrDefault("meshName")
  valid_611448 = validateParameter(valid_611448, JString, required = true,
                                 default = nil)
  if valid_611448 != nil:
    section.add "meshName", valid_611448
  var valid_611449 = path.getOrDefault("virtualRouterName")
  valid_611449 = validateParameter(valid_611449, JString, required = true,
                                 default = nil)
  if valid_611449 != nil:
    section.add "virtualRouterName", valid_611449
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
  var valid_611450 = header.getOrDefault("X-Amz-Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Signature", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Content-Sha256", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Date")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Date", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Credential")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Credential", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Security-Token")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Security-Token", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Algorithm")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Algorithm", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-SignedHeaders", valid_611456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_DeleteRoute_611444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_DeleteRoute_611444; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to delete the route.
  var path_611459 = newJObject()
  add(path_611459, "routeName", newJString(routeName))
  add(path_611459, "meshName", newJString(meshName))
  add(path_611459, "virtualRouterName", newJString(virtualRouterName))
  result = call_611458.call(path_611459, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_611444(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_611445,
                                        base: "/", url: url_DeleteRoute_611446,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_611475 = ref object of OpenApiRestCall_610658
proc url_UpdateVirtualNode_611477(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
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

proc validate_UpdateVirtualNode_611476(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611478 = path.getOrDefault("meshName")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = nil)
  if valid_611478 != nil:
    section.add "meshName", valid_611478
  var valid_611479 = path.getOrDefault("virtualNodeName")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = nil)
  if valid_611479 != nil:
    section.add "virtualNodeName", valid_611479
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
  var valid_611480 = header.getOrDefault("X-Amz-Signature")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Signature", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Content-Sha256", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Date")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Date", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Credential")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Credential", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Security-Token")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Security-Token", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Algorithm")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Algorithm", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-SignedHeaders", valid_611486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_UpdateVirtualNode_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_UpdateVirtualNode_611475; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_611490 = newJObject()
  var body_611491 = newJObject()
  add(path_611490, "meshName", newJString(meshName))
  if body != nil:
    body_611491 = body
  add(path_611490, "virtualNodeName", newJString(virtualNodeName))
  result = call_611489.call(path_611490, nil, nil, nil, body_611491)

var updateVirtualNode* = Call_UpdateVirtualNode_611475(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_611476, base: "/",
    url: url_UpdateVirtualNode_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_611460 = ref object of OpenApiRestCall_610658
proc url_DescribeVirtualNode_611462(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
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

proc validate_DescribeVirtualNode_611461(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611463 = path.getOrDefault("meshName")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "meshName", valid_611463
  var valid_611464 = path.getOrDefault("virtualNodeName")
  valid_611464 = validateParameter(valid_611464, JString, required = true,
                                 default = nil)
  if valid_611464 != nil:
    section.add "virtualNodeName", valid_611464
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
  var valid_611465 = header.getOrDefault("X-Amz-Signature")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Signature", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Content-Sha256", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Date")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Date", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Credential")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Credential", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Security-Token")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Security-Token", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Algorithm")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Algorithm", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-SignedHeaders", valid_611471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_DescribeVirtualNode_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_DescribeVirtualNode_611460; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_611474 = newJObject()
  add(path_611474, "meshName", newJString(meshName))
  add(path_611474, "virtualNodeName", newJString(virtualNodeName))
  result = call_611473.call(path_611474, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_611460(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_611461, base: "/",
    url: url_DescribeVirtualNode_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_611492 = ref object of OpenApiRestCall_610658
proc url_DeleteVirtualNode_611494(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
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

proc validate_DeleteVirtualNode_611493(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611495 = path.getOrDefault("meshName")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "meshName", valid_611495
  var valid_611496 = path.getOrDefault("virtualNodeName")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "virtualNodeName", valid_611496
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
  var valid_611497 = header.getOrDefault("X-Amz-Signature")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Signature", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Content-Sha256", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Date")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Date", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Credential")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Credential", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Security-Token")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Security-Token", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Algorithm")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Algorithm", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-SignedHeaders", valid_611503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611504: Call_DeleteVirtualNode_611492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual node.
  ## 
  let valid = call_611504.validator(path, query, header, formData, body)
  let scheme = call_611504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611504.url(scheme.get, call_611504.host, call_611504.base,
                         call_611504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611504, url, valid)

proc call*(call_611505: Call_DeleteVirtualNode_611492; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_611506 = newJObject()
  add(path_611506, "meshName", newJString(meshName))
  add(path_611506, "virtualNodeName", newJString(virtualNodeName))
  result = call_611505.call(path_611506, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_611492(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_611493, base: "/",
    url: url_DeleteVirtualNode_611494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_611522 = ref object of OpenApiRestCall_610658
proc url_UpdateVirtualRouter_611524(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_611523(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611525 = path.getOrDefault("meshName")
  valid_611525 = validateParameter(valid_611525, JString, required = true,
                                 default = nil)
  if valid_611525 != nil:
    section.add "meshName", valid_611525
  var valid_611526 = path.getOrDefault("virtualRouterName")
  valid_611526 = validateParameter(valid_611526, JString, required = true,
                                 default = nil)
  if valid_611526 != nil:
    section.add "virtualRouterName", valid_611526
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
  var valid_611527 = header.getOrDefault("X-Amz-Signature")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Signature", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Content-Sha256", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Date")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Date", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Credential")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Credential", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Security-Token")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Security-Token", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Algorithm")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Algorithm", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-SignedHeaders", valid_611533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611535: Call_UpdateVirtualRouter_611522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_611535.validator(path, query, header, formData, body)
  let scheme = call_611535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611535.url(scheme.get, call_611535.host, call_611535.base,
                         call_611535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611535, url, valid)

proc call*(call_611536: Call_UpdateVirtualRouter_611522; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_611537 = newJObject()
  var body_611538 = newJObject()
  add(path_611537, "meshName", newJString(meshName))
  if body != nil:
    body_611538 = body
  add(path_611537, "virtualRouterName", newJString(virtualRouterName))
  result = call_611536.call(path_611537, nil, nil, nil, body_611538)

var updateVirtualRouter* = Call_UpdateVirtualRouter_611522(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_611523, base: "/",
    url: url_UpdateVirtualRouter_611524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_611507 = ref object of OpenApiRestCall_610658
proc url_DescribeVirtualRouter_611509(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_611508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611510 = path.getOrDefault("meshName")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = nil)
  if valid_611510 != nil:
    section.add "meshName", valid_611510
  var valid_611511 = path.getOrDefault("virtualRouterName")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "virtualRouterName", valid_611511
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
  var valid_611512 = header.getOrDefault("X-Amz-Signature")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Signature", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Content-Sha256", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Date")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Date", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Credential")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Credential", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Security-Token")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Security-Token", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Algorithm")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Algorithm", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-SignedHeaders", valid_611518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611519: Call_DescribeVirtualRouter_611507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_611519.validator(path, query, header, formData, body)
  let scheme = call_611519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611519.url(scheme.get, call_611519.host, call_611519.base,
                         call_611519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611519, url, valid)

proc call*(call_611520: Call_DescribeVirtualRouter_611507; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_611521 = newJObject()
  add(path_611521, "meshName", newJString(meshName))
  add(path_611521, "virtualRouterName", newJString(virtualRouterName))
  result = call_611520.call(path_611521, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_611507(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_611508, base: "/",
    url: url_DescribeVirtualRouter_611509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_611539 = ref object of OpenApiRestCall_610658
proc url_DeleteVirtualRouter_611541(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_611540(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_611542 = path.getOrDefault("meshName")
  valid_611542 = validateParameter(valid_611542, JString, required = true,
                                 default = nil)
  if valid_611542 != nil:
    section.add "meshName", valid_611542
  var valid_611543 = path.getOrDefault("virtualRouterName")
  valid_611543 = validateParameter(valid_611543, JString, required = true,
                                 default = nil)
  if valid_611543 != nil:
    section.add "virtualRouterName", valid_611543
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
  var valid_611544 = header.getOrDefault("X-Amz-Signature")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Signature", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Content-Sha256", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Date")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Date", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Credential")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Credential", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Security-Token")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Security-Token", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Algorithm")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Algorithm", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-SignedHeaders", valid_611550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611551: Call_DeleteVirtualRouter_611539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_611551.validator(path, query, header, formData, body)
  let scheme = call_611551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611551.url(scheme.get, call_611551.host, call_611551.base,
                         call_611551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611551, url, valid)

proc call*(call_611552: Call_DeleteVirtualRouter_611539; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_611553 = newJObject()
  add(path_611553, "meshName", newJString(meshName))
  add(path_611553, "virtualRouterName", newJString(virtualRouterName))
  result = call_611552.call(path_611553, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_611539(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_611540, base: "/",
    url: url_DeleteVirtualRouter_611541, schemes: {Scheme.Https, Scheme.Http})
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
