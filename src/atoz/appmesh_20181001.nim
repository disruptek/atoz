
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateMesh_21626019 = ref object of OpenApiRestCall_21625435
proc url_CreateMesh_21626021(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMesh_21626020(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626022 = header.getOrDefault("X-Amz-Date")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Date", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Security-Token", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Algorithm", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Signature")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Signature", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Credential")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Credential", valid_21626028
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

proc call*(call_21626030: Call_CreateMesh_21626019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_CreateMesh_21626019; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   body: JObject (required)
  var body_21626032 = newJObject()
  if body != nil:
    body_21626032 = body
  result = call_21626031.call(nil, nil, nil, nil, body_21626032)

var createMesh* = Call_CreateMesh_21626019(name: "createMesh",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/meshes",
                                        validator: validate_CreateMesh_21626020,
                                        base: "/", makeUrl: url_CreateMesh_21626021,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListMeshes_21625781(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeshes_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21625882 = query.getOrDefault("nextToken")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "nextToken", valid_21625882
  var valid_21625883 = query.getOrDefault("limit")
  valid_21625883 = validateParameter(valid_21625883, JInt, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "limit", valid_21625883
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
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_ListMeshes_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_ListMeshes_21625779; nextToken: string = "";
          limit: int = 0): Recallable =
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
  var query_21625980 = newJObject()
  add(query_21625980, "nextToken", newJString(nextToken))
  add(query_21625980, "limit", newJInt(limit))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var listMeshes* = Call_ListMeshes_21625779(name: "listMeshes",
                                        meth: HttpMethod.HttpGet,
                                        host: "appmesh.amazonaws.com",
                                        route: "/meshes",
                                        validator: validate_ListMeshes_21625780,
                                        base: "/", makeUrl: url_ListMeshes_21625781,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_21626064 = ref object of OpenApiRestCall_21625435
proc url_CreateRoute_21626066(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_21626065(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the route.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626067 = path.getOrDefault("virtualRouterName")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "virtualRouterName", valid_21626067
  var valid_21626068 = path.getOrDefault("meshName")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "meshName", valid_21626068
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
  var valid_21626069 = header.getOrDefault("X-Amz-Date")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Date", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Security-Token", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
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

proc call*(call_21626077: Call_CreateRoute_21626064; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_CreateRoute_21626064; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## createRoute
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the route.
  ##   body: JObject (required)
  var path_21626079 = newJObject()
  var body_21626080 = newJObject()
  add(path_21626079, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626079, "meshName", newJString(meshName))
  if body != nil:
    body_21626080 = body
  result = call_21626078.call(path_21626079, nil, nil, nil, body_21626080)

var createRoute* = Call_CreateRoute_21626064(name: "createRoute",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
    validator: validate_CreateRoute_21626065, base: "/", makeUrl: url_CreateRoute_21626066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_21626033 = ref object of OpenApiRestCall_21625435
proc url_ListRoutes_21626035(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutes_21626034(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to list routes.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list routes.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626049 = path.getOrDefault("virtualRouterName")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "virtualRouterName", valid_21626049
  var valid_21626050 = path.getOrDefault("meshName")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "meshName", valid_21626050
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
  var valid_21626051 = query.getOrDefault("nextToken")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "nextToken", valid_21626051
  var valid_21626052 = query.getOrDefault("limit")
  valid_21626052 = validateParameter(valid_21626052, JInt, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "limit", valid_21626052
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
  var valid_21626053 = header.getOrDefault("X-Amz-Date")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Date", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Security-Token", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Algorithm", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Signature")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Signature", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Credential")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Credential", valid_21626059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626060: Call_ListRoutes_21626033; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_21626060.validator(path, query, header, formData, body, _)
  let scheme = call_21626060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626060.makeUrl(scheme.get, call_21626060.host, call_21626060.base,
                               call_21626060.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626060, uri, valid, _)

proc call*(call_21626061: Call_ListRoutes_21626033; virtualRouterName: string;
          meshName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to list routes.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list routes.
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
  var path_21626062 = newJObject()
  var query_21626063 = newJObject()
  add(path_21626062, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626062, "meshName", newJString(meshName))
  add(query_21626063, "nextToken", newJString(nextToken))
  add(query_21626063, "limit", newJInt(limit))
  result = call_21626061.call(path_21626062, query_21626063, nil, nil, nil)

var listRoutes* = Call_ListRoutes_21626033(name: "listRoutes",
                                        meth: HttpMethod.HttpGet,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_ListRoutes_21626034,
                                        base: "/", makeUrl: url_ListRoutes_21626035,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_21626098 = ref object of OpenApiRestCall_21625435
proc url_CreateVirtualNode_21626100(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVirtualNode_21626099(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626101 = path.getOrDefault("meshName")
  valid_21626101 = validateParameter(valid_21626101, JString, required = true,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "meshName", valid_21626101
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
  var valid_21626102 = header.getOrDefault("X-Amz-Date")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Date", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Security-Token", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
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

proc call*(call_21626110: Call_CreateVirtualNode_21626098; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
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
  let valid = call_21626110.validator(path, query, header, formData, body, _)
  let scheme = call_21626110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626110.makeUrl(scheme.get, call_21626110.host, call_21626110.base,
                               call_21626110.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626110, uri, valid, _)

proc call*(call_21626111: Call_CreateVirtualNode_21626098; meshName: string;
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
  var path_21626112 = newJObject()
  var body_21626113 = newJObject()
  add(path_21626112, "meshName", newJString(meshName))
  if body != nil:
    body_21626113 = body
  result = call_21626111.call(path_21626112, nil, nil, nil, body_21626113)

var createVirtualNode* = Call_CreateVirtualNode_21626098(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_21626099, base: "/",
    makeUrl: url_CreateVirtualNode_21626100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_21626081 = ref object of OpenApiRestCall_21625435
proc url_ListVirtualNodes_21626083(protocol: Scheme; host: string; base: string;
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

proc validate_ListVirtualNodes_21626082(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of existing virtual nodes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626084 = path.getOrDefault("meshName")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "meshName", valid_21626084
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
  var valid_21626085 = query.getOrDefault("nextToken")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "nextToken", valid_21626085
  var valid_21626086 = query.getOrDefault("limit")
  valid_21626086 = validateParameter(valid_21626086, JInt, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "limit", valid_21626086
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
  var valid_21626087 = header.getOrDefault("X-Amz-Date")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Date", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Security-Token", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Algorithm", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Signature")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Signature", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Credential")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Credential", valid_21626093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626094: Call_ListVirtualNodes_21626081; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_ListVirtualNodes_21626081; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual nodes.
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
  var path_21626096 = newJObject()
  var query_21626097 = newJObject()
  add(path_21626096, "meshName", newJString(meshName))
  add(query_21626097, "nextToken", newJString(nextToken))
  add(query_21626097, "limit", newJInt(limit))
  result = call_21626095.call(path_21626096, query_21626097, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_21626081(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_21626082, base: "/",
    makeUrl: url_ListVirtualNodes_21626083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_21626131 = ref object of OpenApiRestCall_21625435
proc url_CreateVirtualRouter_21626133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVirtualRouter_21626132(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626134 = path.getOrDefault("meshName")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "meshName", valid_21626134
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
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
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

proc call*(call_21626143: Call_CreateVirtualRouter_21626131; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_21626143.validator(path, query, header, formData, body, _)
  let scheme = call_21626143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626143.makeUrl(scheme.get, call_21626143.host, call_21626143.base,
                               call_21626143.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626143, uri, valid, _)

proc call*(call_21626144: Call_CreateVirtualRouter_21626131; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual router.
  ##   body: JObject (required)
  var path_21626145 = newJObject()
  var body_21626146 = newJObject()
  add(path_21626145, "meshName", newJString(meshName))
  if body != nil:
    body_21626146 = body
  result = call_21626144.call(path_21626145, nil, nil, nil, body_21626146)

var createVirtualRouter* = Call_CreateVirtualRouter_21626131(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_21626132, base: "/",
    makeUrl: url_CreateVirtualRouter_21626133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_21626114 = ref object of OpenApiRestCall_21625435
proc url_ListVirtualRouters_21626116(protocol: Scheme; host: string; base: string;
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

proc validate_ListVirtualRouters_21626115(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626117 = path.getOrDefault("meshName")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "meshName", valid_21626117
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
  var valid_21626118 = query.getOrDefault("nextToken")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "nextToken", valid_21626118
  var valid_21626119 = query.getOrDefault("limit")
  valid_21626119 = validateParameter(valid_21626119, JInt, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "limit", valid_21626119
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
  var valid_21626120 = header.getOrDefault("X-Amz-Date")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Date", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Security-Token", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Algorithm", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Signature")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Signature", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Credential")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Credential", valid_21626126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626127: Call_ListVirtualRouters_21626114; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_21626127.validator(path, query, header, formData, body, _)
  let scheme = call_21626127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626127.makeUrl(scheme.get, call_21626127.host, call_21626127.base,
                               call_21626127.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626127, uri, valid, _)

proc call*(call_21626128: Call_ListVirtualRouters_21626114; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual routers.
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
  var path_21626129 = newJObject()
  var query_21626130 = newJObject()
  add(path_21626129, "meshName", newJString(meshName))
  add(query_21626130, "nextToken", newJString(nextToken))
  add(query_21626130, "limit", newJInt(limit))
  result = call_21626128.call(path_21626129, query_21626130, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_21626114(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_21626115, base: "/",
    makeUrl: url_ListVirtualRouters_21626116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_21626147 = ref object of OpenApiRestCall_21625435
proc url_DescribeMesh_21626149(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMesh_21626148(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Describes an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626150 = path.getOrDefault("meshName")
  valid_21626150 = validateParameter(valid_21626150, JString, required = true,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "meshName", valid_21626150
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
  var valid_21626151 = header.getOrDefault("X-Amz-Date")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Date", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Security-Token", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Algorithm", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Signature")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Signature", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Credential")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Credential", valid_21626157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626158: Call_DescribeMesh_21626147; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_DescribeMesh_21626147; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_21626160 = newJObject()
  add(path_21626160, "meshName", newJString(meshName))
  result = call_21626159.call(path_21626160, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_21626147(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_21626148,
    base: "/", makeUrl: url_DescribeMesh_21626149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_21626161 = ref object of OpenApiRestCall_21625435
proc url_DeleteMesh_21626163(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMesh_21626162(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_21626164 = path.getOrDefault("meshName")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "meshName", valid_21626164
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
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Algorithm", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Signature")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Signature", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Credential")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Credential", valid_21626171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626172: Call_DeleteMesh_21626161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_21626172.validator(path, query, header, formData, body, _)
  let scheme = call_21626172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626172.makeUrl(scheme.get, call_21626172.host, call_21626172.base,
                               call_21626172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626172, uri, valid, _)

proc call*(call_21626173: Call_DeleteMesh_21626161; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_21626174 = newJObject()
  add(path_21626174, "meshName", newJString(meshName))
  result = call_21626173.call(path_21626174, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_21626161(name: "deleteMesh",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com",
                                        route: "/meshes/{meshName}",
                                        validator: validate_DeleteMesh_21626162,
                                        base: "/", makeUrl: url_DeleteMesh_21626163,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_21626191 = ref object of OpenApiRestCall_21625435
proc url_UpdateRoute_21626193(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_21626192(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626194 = path.getOrDefault("virtualRouterName")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "virtualRouterName", valid_21626194
  var valid_21626195 = path.getOrDefault("meshName")
  valid_21626195 = validateParameter(valid_21626195, JString, required = true,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "meshName", valid_21626195
  var valid_21626196 = path.getOrDefault("routeName")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "routeName", valid_21626196
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Signature")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Signature", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Credential")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Credential", valid_21626203
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

proc call*(call_21626205: Call_UpdateRoute_21626191; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_UpdateRoute_21626191; virtualRouterName: string;
          meshName: string; routeName: string; body: JsonNode): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   body: JObject (required)
  var path_21626207 = newJObject()
  var body_21626208 = newJObject()
  add(path_21626207, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626207, "meshName", newJString(meshName))
  add(path_21626207, "routeName", newJString(routeName))
  if body != nil:
    body_21626208 = body
  result = call_21626206.call(path_21626207, nil, nil, nil, body_21626208)

var updateRoute* = Call_UpdateRoute_21626191(name: "updateRoute",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_UpdateRoute_21626192, base: "/", makeUrl: url_UpdateRoute_21626193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_21626175 = ref object of OpenApiRestCall_21625435
proc url_DescribeRoute_21626177(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRoute_21626176(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626178 = path.getOrDefault("virtualRouterName")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "virtualRouterName", valid_21626178
  var valid_21626179 = path.getOrDefault("meshName")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "meshName", valid_21626179
  var valid_21626180 = path.getOrDefault("routeName")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "routeName", valid_21626180
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
  var valid_21626181 = header.getOrDefault("X-Amz-Date")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Date", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Security-Token", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626188: Call_DescribeRoute_21626175; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_DescribeRoute_21626175; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  var path_21626190 = newJObject()
  add(path_21626190, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626190, "meshName", newJString(meshName))
  add(path_21626190, "routeName", newJString(routeName))
  result = call_21626189.call(path_21626190, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_21626175(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_21626176, base: "/",
    makeUrl: url_DescribeRoute_21626177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_21626209 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoute_21626211(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_21626210(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to delete the route.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626212 = path.getOrDefault("virtualRouterName")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "virtualRouterName", valid_21626212
  var valid_21626213 = path.getOrDefault("meshName")
  valid_21626213 = validateParameter(valid_21626213, JString, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "meshName", valid_21626213
  var valid_21626214 = path.getOrDefault("routeName")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "routeName", valid_21626214
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
  var valid_21626215 = header.getOrDefault("X-Amz-Date")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Date", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Security-Token", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Algorithm", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Signature")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Signature", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Credential")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Credential", valid_21626221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626222: Call_DeleteRoute_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_21626222.validator(path, query, header, formData, body, _)
  let scheme = call_21626222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626222.makeUrl(scheme.get, call_21626222.host, call_21626222.base,
                               call_21626222.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626222, uri, valid, _)

proc call*(call_21626223: Call_DeleteRoute_21626209; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to delete the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  var path_21626224 = newJObject()
  add(path_21626224, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626224, "meshName", newJString(meshName))
  add(path_21626224, "routeName", newJString(routeName))
  result = call_21626223.call(path_21626224, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_21626209(name: "deleteRoute",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DeleteRoute_21626210, base: "/", makeUrl: url_DeleteRoute_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_21626240 = ref object of OpenApiRestCall_21625435
proc url_UpdateVirtualNode_21626242(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVirtualNode_21626241(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626243 = path.getOrDefault("meshName")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "meshName", valid_21626243
  var valid_21626244 = path.getOrDefault("virtualNodeName")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "virtualNodeName", valid_21626244
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
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

proc call*(call_21626253: Call_UpdateVirtualNode_21626240; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_UpdateVirtualNode_21626240; meshName: string;
          virtualNodeName: string; body: JsonNode): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  ##   body: JObject (required)
  var path_21626255 = newJObject()
  var body_21626256 = newJObject()
  add(path_21626255, "meshName", newJString(meshName))
  add(path_21626255, "virtualNodeName", newJString(virtualNodeName))
  if body != nil:
    body_21626256 = body
  result = call_21626254.call(path_21626255, nil, nil, nil, body_21626256)

var updateVirtualNode* = Call_UpdateVirtualNode_21626240(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_21626241, base: "/",
    makeUrl: url_UpdateVirtualNode_21626242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_21626225 = ref object of OpenApiRestCall_21625435
proc url_DescribeVirtualNode_21626227(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeVirtualNode_21626226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626228 = path.getOrDefault("meshName")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "meshName", valid_21626228
  var valid_21626229 = path.getOrDefault("virtualNodeName")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "virtualNodeName", valid_21626229
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
  var valid_21626230 = header.getOrDefault("X-Amz-Date")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Date", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Security-Token", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Algorithm", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Signature")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Signature", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Credential")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Credential", valid_21626236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626237: Call_DescribeVirtualNode_21626225; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_DescribeVirtualNode_21626225; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_21626239 = newJObject()
  add(path_21626239, "meshName", newJString(meshName))
  add(path_21626239, "virtualNodeName", newJString(virtualNodeName))
  result = call_21626238.call(path_21626239, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_21626225(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_21626226, base: "/",
    makeUrl: url_DescribeVirtualNode_21626227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_21626257 = ref object of OpenApiRestCall_21625435
proc url_DeleteVirtualNode_21626259(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualNode_21626258(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626260 = path.getOrDefault("meshName")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "meshName", valid_21626260
  var valid_21626261 = path.getOrDefault("virtualNodeName")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "virtualNodeName", valid_21626261
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
  var valid_21626262 = header.getOrDefault("X-Amz-Date")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Date", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Security-Token", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Algorithm", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Signature")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Signature", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Credential")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Credential", valid_21626268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626269: Call_DeleteVirtualNode_21626257; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing virtual node.
  ## 
  let valid = call_21626269.validator(path, query, header, formData, body, _)
  let scheme = call_21626269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626269.makeUrl(scheme.get, call_21626269.host, call_21626269.base,
                               call_21626269.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626269, uri, valid, _)

proc call*(call_21626270: Call_DeleteVirtualNode_21626257; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_21626271 = newJObject()
  add(path_21626271, "meshName", newJString(meshName))
  add(path_21626271, "virtualNodeName", newJString(virtualNodeName))
  result = call_21626270.call(path_21626271, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_21626257(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_21626258, base: "/",
    makeUrl: url_DeleteVirtualNode_21626259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_21626287 = ref object of OpenApiRestCall_21625435
proc url_UpdateVirtualRouter_21626289(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVirtualRouter_21626288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626290 = path.getOrDefault("virtualRouterName")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "virtualRouterName", valid_21626290
  var valid_21626291 = path.getOrDefault("meshName")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "meshName", valid_21626291
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
  var valid_21626292 = header.getOrDefault("X-Amz-Date")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Date", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Security-Token", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Algorithm", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Signature")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Signature", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Credential")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Credential", valid_21626298
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

proc call*(call_21626300: Call_UpdateVirtualRouter_21626287; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_UpdateVirtualRouter_21626287;
          virtualRouterName: string; meshName: string; body: JsonNode): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   body: JObject (required)
  var path_21626302 = newJObject()
  var body_21626303 = newJObject()
  add(path_21626302, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626302, "meshName", newJString(meshName))
  if body != nil:
    body_21626303 = body
  result = call_21626301.call(path_21626302, nil, nil, nil, body_21626303)

var updateVirtualRouter* = Call_UpdateVirtualRouter_21626287(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_21626288, base: "/",
    makeUrl: url_UpdateVirtualRouter_21626289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_21626272 = ref object of OpenApiRestCall_21625435
proc url_DescribeVirtualRouter_21626274(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_DescribeVirtualRouter_21626273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626275 = path.getOrDefault("virtualRouterName")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "virtualRouterName", valid_21626275
  var valid_21626276 = path.getOrDefault("meshName")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "meshName", valid_21626276
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
  var valid_21626277 = header.getOrDefault("X-Amz-Date")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Date", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Security-Token", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Algorithm", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Signature")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Signature", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Credential")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Credential", valid_21626283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626284: Call_DescribeVirtualRouter_21626272;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_21626284.validator(path, query, header, formData, body, _)
  let scheme = call_21626284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626284.makeUrl(scheme.get, call_21626284.host, call_21626284.base,
                               call_21626284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626284, uri, valid, _)

proc call*(call_21626285: Call_DescribeVirtualRouter_21626272;
          virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  var path_21626286 = newJObject()
  add(path_21626286, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626286, "meshName", newJString(meshName))
  result = call_21626285.call(path_21626286, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_21626272(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_21626273, base: "/",
    makeUrl: url_DescribeVirtualRouter_21626274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_21626304 = ref object of OpenApiRestCall_21625435
proc url_DeleteVirtualRouter_21626306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualRouter_21626305(path: JsonNode; query: JsonNode;
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
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_21626307 = path.getOrDefault("virtualRouterName")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "virtualRouterName", valid_21626307
  var valid_21626308 = path.getOrDefault("meshName")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "meshName", valid_21626308
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
  var valid_21626309 = header.getOrDefault("X-Amz-Date")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Date", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Security-Token", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Algorithm", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Signature")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Signature", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Credential")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Credential", valid_21626315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626316: Call_DeleteVirtualRouter_21626304; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_21626316.validator(path, query, header, formData, body, _)
  let scheme = call_21626316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626316.makeUrl(scheme.get, call_21626316.host, call_21626316.base,
                               call_21626316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626316, uri, valid, _)

proc call*(call_21626317: Call_DeleteVirtualRouter_21626304;
          virtualRouterName: string; meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  var path_21626318 = newJObject()
  add(path_21626318, "virtualRouterName", newJString(virtualRouterName))
  add(path_21626318, "meshName", newJString(meshName))
  result = call_21626317.call(path_21626318, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_21626304(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_21626305, base: "/",
    makeUrl: url_DeleteVirtualRouter_21626306,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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